function BatchAssignObjects() {
    this.setupBinds();
}

BatchAssignObjects.prototype.addJSWonderment = function() {
    $('#objects_assigned .table-record-actions .btn-group').each(function () {
        $(this).append($('<button class="btn btn-xs btn-danger object-remove-btn">Remove</button>'));
    })
};

BatchAssignObjects.prototype.setupBinds = function() {
    $(document).on('change', 'select#model', function (e) {
        var model = $(this).val();
	$('.batch-model-help').hide();
	var help = $('.batch-model-help-' + model);

	help.show();

        // reinitialise the linkers with the new set of types
        // FIXME: is there a saner way to do this?
    $("#batch_adds_linker").closest('.linker-wrapper').find('.linker-browse-btn').off('click');
	$('#batch_adds_linker').data('types', help.data('types'));
	$("#batch_adds_linker").removeClass('initialised');
	$("#batch_adds_linker").linker();
	$("#batch_adds_linker").closest('.linker-wrapper').find('.token-input-list').first().remove();
    $("#batch_removes_linker").closest('.linker-wrapper').find('.linker-browse-btn').off('click');
	$('#batch_removes_linker').data('types', help.data('types'));
	$("#batch_removes_linker").removeClass('initialised');
	$("#batch_removes_linker").linker();
	$("#batch_removes_linker").closest('.linker-wrapper').find('.token-input-list').first().remove();

	if (model == '') {
            $('button[type=submit]').attr('disabled', 'disabled');
	    $('#objects_add').hide();
	    $('#objects_remove').hide();
        } else {
            $('button[type=submit]').removeAttr('disabled');
            $('.batch-assign-type-label').text($(this).find(':selected').text());
	    $('#objects_add').show();
	    $('#objects_remove').show();
	}
    });

    $(document).on('click', '.object-remove-btn', function (e) {
        e.preventDefault();

        var linker = $('#batch_removes_linker');
        var json = $(this).closest('tr').data('resolved-record');

        var existing_entries = linker.tokenInput('get');

        if (existing_entries.map(function (entry) { return entry.id } ).indexOf(json.uri) >= 0) {
            return false;
        }

        linker.tokenInput('add',
                          {
                              id: json.uri,
                              name: json.display_string,
                              json: json
                          });

        return false;
    });

    $('#clear-assign-form').on('submit', function () {
        if ($(this).data('confirmation_received')) {
            return true;
        } else {
            var self = $(this);

            AS.openCustomModal("clearAssignModal", $("#clear_assign_modal_template").data("title"), AS.renderTemplate("clear_assign_modal_template"), null, {}, self.find('#clear-assign-btn'));
            $("#confirmButton", "#clearAssignModal").click(function() {
                $(".btn", "#clearAssignModal").attr("disabled", "disabled");
                self.data('confirmation_received', true).submit();
            });

            return false;
        }

    });
}

window.assign_objects_form = new BatchAssignObjects();
