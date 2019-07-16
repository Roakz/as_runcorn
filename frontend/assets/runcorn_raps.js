(function() {
    function RuncornRAPs($container) {
        $('.attach-rap-button', $container).each(function() {
            new RuncornRAPAttachWorkflow($(this));
        });
        $('.edit-rap-button', $container).each(function() {
            new RuncornRAPEditWorkflow($(this));
        });
    }

    function RuncornRAPAttachWorkflow($button) {
        this.$button = $button;
        this.recordURI = this.$button.data('uri');

        var self = this;
        this.$button.on('click', function(event) {
            event.stopImmediatePropagation();
            event.preventDefault();

            self.showModal();
        });
    };

    RuncornRAPAttachWorkflow.prototype.setupForm = function($modal) {
        var self = this;

        $modal.find('form').ajaxForm({
            beforeSubmit: function() {
                $('#confirmRAPAttachButton', $modal).prop('disabled', true);
            },
            error: function(jqXHR, textStatus, errorThrown) {
                $modal.find('.modal-body').html(jqXHR.responseText);
                $('#confirmRAPAttachButton', $modal).prop('disabled', false);
                self.setupForm($modal);
            },
            success: function(html) {
                location.reload();
            }
        });
    };

    RuncornRAPAttachWorkflow.prototype.showModal = function() {
        var self = this;
        var $content = $(AS.renderTemplate("runcornRAPAttachWorkflowTemplate"));
        var $modal = AS.openCustomModal("runcornRAPAttachWorkflow", 'Attach and Apply RAP', $content.html(), 'large', {keyboard: false}, this.$button);

        $.ajax({
            url: APP_PATH + 'raps/attach',
            data: {uri: this.recordURI},
            type: 'get',
            dataType: 'html',
            success: function (html) {
                $modal.find('.modal-body').html(html);
                $('#confirmRAPAttachButton', $modal)
                    .prop('disabled', false)
                    .on('click', function() {
                        $modal.find('form').submit();
                    });
                self.setupForm($modal);
            }
        });
    };


    function RuncornRAPEditWorkflow($button) {
        this.$button = $button;
        this.recordURI = this.$button.data('record-uri');
        this.rapURI = this.$button.data('rap-uri');

        var self = this;
        this.$button.on('click', function(event) {
            event.stopImmediatePropagation();
            event.preventDefault();

            self.showModal();
        });
    };

    RuncornRAPEditWorkflow.prototype.setupForm = function($modal) {
        var self = this;

        $modal.find('form').ajaxForm({
            beforeSubmit: function() {
                $('#confirmRAPAttachButton', $modal).prop('disabled', true);
            },
            error: function(jqXHR, textStatus, errorThrown) {
                $modal.find('.modal-body').html(jqXHR.responseText);
                $('#confirmRAPAttachButton', $modal).prop('disabled', false);
                self.setupForm($modal);
            },
            success: function(html) {
                location.reload();
            }
        });
    };

    RuncornRAPEditWorkflow.prototype.showModal = function() {
        var self = this;
        var $content = $(AS.renderTemplate("runcornRAPAttachWorkflowTemplate"));
        var $modal = AS.openCustomModal("runcornRAPAttachWorkflow", 'Edit RAP', $content.html(), 'large', {keyboard: false}, this.$button);

        $.ajax({
            url: APP_PATH + 'raps/edit',
            data: {
                uri: this.recordURI,
                rap_uri: this.rapURI
            },
            type: 'get',
            dataType: 'html',
            success: function (html) {
                $modal.find('.modal-body').html(html);
                $('#confirmRAPAttachButton', $modal)
                    .prop('disabled', false)
                    .on('click', function() {
                        $modal.find('form').submit();
                    });
                self.setupForm($modal);
            }
        });
    };

    function RAPSummary($section) {
        this.$section = $section;
        this.recordURI = $section.data('uri');
        this.load();
    };

    RAPSummary.prototype.load = function() {
        var self = this;

        $.ajax({
            url: APP_PATH + 'raps/summary',
            data: {uri: self.recordURI},
            type: 'get',
            dataType: 'html',
            success: function (html) {
                self.$section.find('.subrecord-form-fields').html(html);
                $(document).trigger('loadedrecordform.aspace', [self.$section]);
            }
        });
    };

    window.RuncornRAPAttachWorkflow = RuncornRAPAttachWorkflow;
    window.RuncornRAPEditWorkflow = RuncornRAPEditWorkflow;
    window.RuncornRAPs = RuncornRAPs;
    window.RAPSummary = RAPSummary;
})();