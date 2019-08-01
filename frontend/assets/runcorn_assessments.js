(function(exports) {

    function RuncornAssessmentGenerateTreatmentsWorkflow($button) {
        var self = this;
        self.assessmentId = $button.data('assessmentid');
        self.$button = $button;
        self.$button.on('click', function() {
            self.showModal();
        });
    };

    RuncornAssessmentGenerateTreatmentsWorkflow.prototype.setupForm = function($modal) {
        var self = this;

        $modal.find('form').ajaxForm({
            beforeSubmit: function() {
                $modal.find('.modal-body :input').prop('disabled', true);
                $('#confirmGenerateTreatmentsButton', $modal).prop('disabled', true);
            },
            error: function(jqXHR, textStatus, errorThrown) {
                $modal.find('.modal-body').html(jqXHR.responseText);
                $('#confirmGenerateTreatmentsButton', $modal).prop('disabled', false);
                self.setupForm($modal);
            },
            success: function(html) {
                $modal.find('.modal-body').html($('<div>').addClass('alert alert-success').text(html));
                $('#confirmGenerateTreatmentsButton', $modal).remove();
                $('.btn-cancel', $modal).text('Close');
            }
        });
    };

    RuncornAssessmentGenerateTreatmentsWorkflow.prototype.showModal = function() {
        var self = this;
        var $content = $(AS.renderTemplate("runcornAssessmentGenerateTreatmentsWorkflowTemplate"));
        var $modal = AS.openCustomModal("runcornAssessmentGenerateTreatmentsWorkflow", 'Generate Treatments', $content.html(), 'large', {keyboard: false}, this.$button);

        $.ajax({
            url: APP_PATH + 'assessments/'+self.assessmentId+'/generate_treatments',
            type: 'get',
            dataType: 'html',
            success: function (html) {
                $modal.find('.modal-body').html(html);
                $('#confirmGenerateTreatmentsButton', $modal)
                    .prop('disabled', false)
                    .on('click', function() {
                        $modal.find('form').submit();
                    });
                self.setupForm($modal);
            }
        });
    };

    window.RuncornAssessmentGenerateTreatmentsWorkflow = RuncornAssessmentGenerateTreatmentsWorkflow;

    $(document).ready(function() {
        new RuncornAssessmentGenerateTreatmentsWorkflow($('#runcornGenerateTreatmentsButton'));
    });

})(window);