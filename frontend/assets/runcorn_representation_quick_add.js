(function(exports) {
    function RepresentationQuickAdd($section) {
        this.$section = $section;
        this.$mainButton = this.$section.find('h3 button');
        this.addButton();
    };

    RepresentationQuickAdd.prototype.addButton = function() {
        var self = this;
        self.$button = $('<a>')
                            .attr('href', 'javascript:void(0)')
                            .text('Quick Add')
                            .addClass('btn btn-sm btn-default pull-right');
        self.$button.on('click mousedown keydown', function(event) {
            self.setQuickForm(event);
        });
        self.$mainButton.on('click mousedown keydown', function(event) {
            self.setFullForm(event);
        });
        self.$mainButton.before(self.$button)
    };

    RepresentationQuickAdd.prototype.setQuickForm = function(event) {
        this.$section.data('template', 'template_digital_representation_quick_add');
        return true;
    };


    RepresentationQuickAdd.prototype.setFullForm = function(event) {
        this.$section.data('template', 'template_digital_representation');
        return true;
    };

    exports.RepresentationQuickAdd = RepresentationQuickAdd;

    $(document).on("loadedrecordform.aspace", function(event, $pane) {
        if ($pane.find('#archival_object_form').length > 0) {
            if ($pane.find('#archival_object_digital_representations').length > 0) {
                new RepresentationQuickAdd($pane.find('#archival_object_digital_representations'));
            }
        }
    });
}(window));
