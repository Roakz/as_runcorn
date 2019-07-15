(function() {
    function RuncornRAPs($container) {
        $('.attach-rap-button', $container).each(function() {
            new RuncornRAPAttachWorkflow($(this));
        });
    }

    function RuncornRAPAttachWorkflow($button) {
        this.$button = $button;
        this.recordURI = this.$button.data('uri');

        var self = this;
        this.$button.on('click', function() {
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

    window.RuncornRAPAttachWorkflow = RuncornRAPAttachWorkflow;
    window.RuncornRAPs = RuncornRAPs;
})();