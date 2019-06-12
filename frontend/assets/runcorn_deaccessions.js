(function() {
    function RuncornDeaccessionWorkflow($button, $context) {
        this.$button = $button;
        this.$context = $context;
        this.$section = this.$button.closest('section.subrecord-form');
        this.$origButton = this.$section.find(' > .subrecord-form-heading > button');
        this.record_uri = this.getURIForContext();
        this.showModal();
    };

    RuncornDeaccessionWorkflow.prototype.getURIForContext = function() {
        if (this.$context.closest('#archival_object_digital_representations').length == 1) {
            return this.$context.find(':input[id$=_existing_ref_]').val();
        } else if (this.$context.closest('#archival_object_physical_representations').length == 1) {
            return this.$context.find(':input[id$=_existing_ref_]').val();
        } else {
            return this.$context.find(':input[id=uri]').val();
        }
    };

    RuncornDeaccessionWorkflow.prototype.showModal = function() {
        var self = this;

        var $content = $(AS.renderTemplate("runcornDeaccessionWorkflowTemplate"));

        var $modal = AS.openCustomModal("runcornDeaccessionWorkflow", 'Add Deaccession Record', $content.html(), 'full', {keyboard: false}, this.$button);

        $modal.on('click', '#confirmDeaccessionButton', function() {
            self.$origButton.trigger('click');
            self.$button.hide();
            self.$origButton.show();
            $modal.modal('hide');
        });

        $.ajax({
            url: APP_PATH + 'deaccessions/affected_records',
            data: {uri: self.record_uri},
            type: 'get',
            dataType: 'html',
            success: function (html) {
                $modal.find('.affected-deaccession-records').html(html);
            }
        });
    };


    function RuncornDeaccessionSubrecord($section) {
        if ($section.data('RuncornDeaccessionSubrecord')) {
            return;
        }

        this.$section = $section;
        this.$context = this.findRecordContext();
        if (this.$section.length > 0) {
            if (this.isNewRecord()) {
                this.hideSection();
            } else {
                if (!this.isDeaccessionedAlready()) {
                    this.$addSubrecordButton = this.$section.find('> .subrecord-form-heading > button');
                    this.hideAddAction();
                    this.showWorkflowButton();
                }
            }
        }

        this.$section.data('RuncornDeaccessionSubrecord', this);
    };

    RuncornDeaccessionSubrecord.prototype.isNewRecord = function() {
        if (this.$context.is('li')) {
            return this.$section.find(':input[id$=_existing_ref_]').val() == "";
        } else {
            return this.$context.find(':hidden[id="id"]').val() == "";
        }
    };

    RuncornDeaccessionSubrecord.prototype.hideSection = function() {
        $('#archivesSpaceSidebar').find('a[href="#'+this.$section.attr('id')+'"]').remove();
        this.$section.remove();
    };

    RuncornDeaccessionSubrecord.prototype.hideAddAction = function() {
        this.$addSubrecordButton.hide();
    };

    RuncornDeaccessionSubrecord.prototype.isDeaccessionedAlready = function() {
        return this.$section.find(' > .subrecord-form-container > .subrecord-form-list li').length > 0 || this.$context.find('.record-is-deaccessioned').length > 0;
    }

    RuncornDeaccessionSubrecord.prototype.showWorkflowButton = function() {
        var self = this;
        var $btn = $('<a>').addClass('btn').addClass('btn-sm').addClass('btn-warning').addClass('deaccession-the-record-button').css('marginTop', '10px').text('Add Deaccession Record');
        self.$section.find('> .subrecord-form-container').append($btn);
        self.$section.on('click', '.deaccession-the-record-button', function(event) {
            new RuncornDeaccessionWorkflow($(this), self.$context);
        });
    };

    RuncornDeaccessionSubrecord.prototype.findRecordContext = function() {
        if (this.$section.closest('#archival_object_digital_representations').length == 1) {
            return this.$section.closest('li');
        } else if (this.$section.closest('#archival_object_physical_representations').length == 1) {
            return this.$section.closest('li');
        } else {
            return this.$section.closest('form');
        }
    };

    window.RuncornDeaccessionWorkflow = RuncornDeaccessionWorkflow;
    window.RuncornDeaccessionSubrecord = RuncornDeaccessionSubrecord;
})();