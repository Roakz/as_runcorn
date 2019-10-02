(function(exports) {
    function RuncornRAPs($container, opts) {
        this.opts = opts;
        var self = this;

        this.$form = $container.find('.record-pane:first');
        if (this.$form.data('RuncornRAPs')) {
            return;
        }
        this.$form.data('RuncornRAPs', this);

        $('.attach-rap-button', this.$form).each(function() {
            new RuncornRAPAttachWorkflow($(this), self);
        });
        $('.edit-rap-button', this.$form).each(function() {
            new RuncornRAPEditWorkflow($(this), self);
        });

        new RunctionRAPsTreeOverrides(self);
        new RAPsPublishable(self);
    }

    RuncornRAPs.prototype.setupAccessCategoryHints = function($form) {
        var self = this;
        var $accessCategoryInput = $('#rap_access_category_', $form);
        var $yearsInput = $('#rap_years_', $form);

        $yearsInput.after('<small id="rapYearsHelp" class="form-text text-muted"></small>');

        var $hintContainer = $('#rapYearsHelp', $form);

        function addHelpfulHint() {
            if (self.opts.forever_closed_access_categories.indexOf($accessCategoryInput.val()) >= 0) {
                $hintContainer.text('Years cannot be set as Access Category implies closed permanently');
            } else if ($accessCategoryInput.val() === 'N/A') {
                $hintContainer.text('Set to 0 if open; leave empty if closed permanently; otherwise provide a value from 1 to 100');
            } else {
                $hintContainer.text('Set to 0 if open; otherwise provide a value from 1 to 100 (default 100)');
            }
        }

        addHelpfulHint();
        $accessCategoryInput.on('change', function() {
            addHelpfulHint();
        });
    };

    RuncornRAPs.prototype.setupForeverClosedAccessCategories = function($form) {
        var self = this;
        var $accessCategoryInput = $('#rap_access_category_', $form);
        var $yearsInput = $('#rap_years_', $form);

        function checkAndApplyForeverClosed() {
            if (self.opts.forever_closed_access_categories.indexOf($accessCategoryInput.val()) >= 0) {
                $yearsInput.val("").prop('disabled', true);
            } else {
                $yearsInput.prop('disabled', false);
            }
        };

        checkAndApplyForeverClosed();
        $accessCategoryInput.on('change', function() {
            checkAndApplyForeverClosed();
        });
    };

    RuncornRAPs.prototype.showAffectedRecordCounts = function($form) {
        $.ajax({
            method: 'GET',
            url: '/raps/attach_summary',
            data: {
                uri: $form.find(':hidden[name=uri]').val()
            },
            success: function(html) {
                $form.find('#rap-counts-summary').html(html);
            }
        });
    }

    function RuncornRAPAttachWorkflow($button, runcornRAPs) {
        this.$button = $button;
        this.recordURI = this.$button.data('uri');
        this.runcornRAPs = runcornRAPs;

        var self = this;
        this.$button.on('click', function(event) {
            event.stopImmediatePropagation();
            event.preventDefault();

            self.showModal();
        });
    };

    RuncornRAPAttachWorkflow.prototype.setupForm = function($modal) {
        var self = this;

        self.runcornRAPs.setupForeverClosedAccessCategories($modal.find('form'));
        self.runcornRAPs.setupAccessCategoryHints($modal.find('form'));
        self.runcornRAPs.showAffectedRecordCounts($modal.find('form'));

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


    function RuncornRAPEditWorkflow($button, runcornRAPs) {
        this.$button = $button;
        this.recordURI = this.$button.data('attached-uri');
        this.rapURI = this.$button.data('rap-uri');
        this.runcornRAPs = runcornRAPs;

        var self = this;
        this.$button.on('click', function(event) {
            event.stopImmediatePropagation();
            event.preventDefault();

            self.showModal();
        });
    };

    RuncornRAPEditWorkflow.prototype.setupForm = function($modal) {
        var self = this;

        self.runcornRAPs.setupForeverClosedAccessCategories($modal.find('form'));
        self.runcornRAPs.setupAccessCategoryHints($modal.find('form'));
        self.runcornRAPs.showAffectedRecordCounts($modal.find('form'));

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

    function RunctionRAPsTreeOverrides(runcornRAPs) {
        this.runcornRAPs = runcornRAPs;

        if (exports.tree && exports.tree.large_tree) {
            this.overrideLargeTreeReparentNodes();
        }
    };

    function checkWhetherMoveAffectsRAPs(new_parent, nodes, position, callback) {
        var parent_uri = $(new_parent).data('uri');

        var node_uris = nodes.map(function (node) {
            return $(node).data('uri');
        });

        $.ajax({
            url: APP_PATH + 'raps/check_tree_move',
            data: {
                parent_uri: parent_uri,
                node_uris: node_uris,
                position: position
            },
            type: 'POST',
            dataType: 'json',
            success: function (response) {
                callback(response);
            },
            error: function () {
                callback({
                    status: false,
                });
            }
        });
    };

    RunctionRAPsTreeOverrides.prototype.overrideLargeTreeReparentNodes = function() {
        var self = this;
        exports.tree.large_tree.reparentNodes = function(new_parent, nodes, position) {
            function callOriginal() {
                $.proxy(exports.LargeTree.prototype.reparentNodes, exports.tree.large_tree)(new_parent, nodes, position).done(function() {
                    exports.tree.dragdrop.resetState();
                });
            }

            checkWhetherMoveAffectsRAPs(new_parent, nodes, position,
                                        function (changed) {
                                            if (changed.status) {
                                                var $modal = self.showModal();
                                                $modal.on('click', '#confirmRAPReparentButton', function() {
                                                    $modal.modal('hide');
                                                    callOriginal();
                                                });

                                                $modal.on('click', '.btn-cancel', function() {
                                                    exports.tree.dragdrop.resetState();
                                                });
                                            } else {
                                                callOriginal();
                                            }
                                        });
            return {
                'done' : $.noop
            };
        }
    };

    RunctionRAPsTreeOverrides.prototype.showModal = function() {
        var $content = $(AS.renderTemplate("runcornRAPReparentNodesConfirmationTemplate"));
        return AS.openCustomModal("runcornRAPReparentNodesConfirmation", 'Confirm Move', $content.html(), 'large', {keyboard: false});
    };

    function RAPsPublishable(runcornRAPs) {
        this.RuncornRAPs = runcornRAPs;
        var $checkbox = $(':checkbox[name="archival_object[publish]"]', runcornRAPs.$container);
        var $publishable = $(':hidden[name="archival_object[publishable]"]', runcornRAPs.$container);
        if ($publishable.length > 0 && $checkbox.length > 0) {
            if ($publishable.val() === 'false') {
                $checkbox.prop('checked', false).prop('disabled', true);
                $checkbox.after('<span class="help-inline"><span class="text-muted">Record cannot be published due to RAP restriction</span></span>');
            }
        }
    }

    exports.RuncornRAPAttachWorkflow = RuncornRAPAttachWorkflow;
    exports.RuncornRAPEditWorkflow = RuncornRAPEditWorkflow;
    exports.RuncornRAPs = RuncornRAPs;
    exports.RAPSummary = RAPSummary;
    exports.RunctionRAPsTreeOverrides = RunctionRAPsTreeOverrides;
    exports.RAPsPublishable = RAPsPublishable;
})(window);
