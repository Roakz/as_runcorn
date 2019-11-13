(function(exports) {
    function RuncornRAPs($target, opts) {
        this.opts = opts;
        var self = this;

        this.$container = $target.find('.record-pane:first');
        if (this.$container.data('RuncornRAPs')) {
            return;
        }
        this.$container.data('RuncornRAPs', this);

        $('.attach-rap-button', this.$container).each(function() {
            new RuncornRAPAttachWorkflow($(this), self);
        });
        $('.edit-rap-button', this.$container).each(function() {
            new RuncornRAPEditWorkflow($(this), self);
        });

        new RunctionRAPsTreeOverrides(self);
        new RAPsPublishable(self);
    }

    RuncornRAPs.prototype.setupForeverClosedAccessCategories = function($form) {
        var self = this;
        var $accessCategoryInput = $('#rap_access_category_', $form);
        var $openAccessMetadataInput = $('#rap_open_access_metadata_', $form);
        var $yearsInput = $('#rap_years_', $form);

        $yearsInput.after('<small id="rapYearsHelp" class="form-text text-muted"></small>');
        $openAccessMetadataInput.after('<small id="rapOpenAccessMetadataHelp" class="help-inline text-muted"></small>');
        $accessCategoryInput.after('<small id="rapAccessCategoryHelp" class="form-text text-muted"></small>');

        var $yearsHint = $('#rapYearsHelp', $form);
        var $openAccessMetadataHint = $('#rapOpenAccessMetadataHelp', $form);
        var $accessCategoryHint = $('#rapAccessCategoryHelp', $form);

        function applyMagic() {
            if (self.opts.forever_closed_access_categories.indexOf($accessCategoryInput.val()) >= 0 || $accessCategoryInput.val() === 'N/A') {
                $yearsHint.text('Years cannot be set as Access Category implies closed permanently');
                $yearsInput.val("").prop('disabled', true);
            } else if ($accessCategoryInput.val() === '') {
                $yearsHint.text('Leave empty if closed permanently; Set to 0 if open; otherwise provide a value from 1 to 100');
                $yearsInput.prop('disabled', false);
            } else {
                $yearsHint.text('Set to 0 if open; otherwise provide a value from 1 to 100 (default 100)');
                $yearsInput.prop('disabled', false);
            }

            if ($accessCategoryInput.val() === 'N/A') {
                $openAccessMetadataHint.text('Publish Details cannot be set as Access Category implies closed permanently');
                $openAccessMetadataInput.prop('disabled', true);
            } else {
                $openAccessMetadataHint.text('');
                $openAccessMetadataInput.prop('disabled', false);
            }

            if ($accessCategoryInput.val() === '') {
                $accessCategoryHint.text('An empty category implies the RAP is incomplete but Open Access Metadata and Years/RAP expiry will still apply if provided');
            } else {
                $accessCategoryHint.text('');
            }
        }

        applyMagic();
        $accessCategoryInput.on('change', function() {
            applyMagic();
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
    };

    RuncornRAPs.prototype.hasFormChanged = function() {
        var $form = $(this.$container).closest('form');
        if ($form.length > 0) {
            return $form.data('form_changed');
        } else {
            // no form, no change!
            return false;
        }
    };

    RuncornRAPs.prototype.onFormChange = function(callback) {
        var self = this;
        var $form = $(self.$container).closest('form');
        if ($form.length > 0) {
            $form.on('formchanged.aspace', function() {
                callback();
            });
        } else {
            // no form, nothing to do!
        }
    };

    function RuncornRAPAttachWorkflow($button, runcornRAPs) {
        this.$button = $button;
        this.recordURI = this.$button.data('uri');
        this.runcornRAPs = runcornRAPs;

        var self = this;
        this.$button.on('click', function(event) {
            event.stopImmediatePropagation();
            event.preventDefault();

            if (runcornRAPs.hasFormChanged(this)) {
                return;
            }


            self.showModal();
        });

        runcornRAPs.onFormChange(function() {
            self.$button.prop('disabled', true);
            self.$button.closest('section').find('.raps-form-changed-warning').show();
        });
    };

    RuncornRAPAttachWorkflow.prototype.setupForm = function($modal) {
        var self = this;

        self.runcornRAPs.setupForeverClosedAccessCategories($modal.find('form'));
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

            if (runcornRAPs.hasFormChanged(this)) {
                return;
            }

            self.showModal();
        });

        runcornRAPs.onFormChange(function() {
            self.$button.prop('disabled', true);
        });
    };

    RuncornRAPEditWorkflow.prototype.setupForm = function($modal) {
        var self = this;

        self.runcornRAPs.setupForeverClosedAccessCategories($modal.find('form'));
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
