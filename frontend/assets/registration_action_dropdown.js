// this adapted from event add
$(function () {

	var init = function () {
	    $('.btn-toolbar > .btn-group').prepend(REGISTRATION_ACTION_DROPDOWN);

            if (REGISTRATION_STATE == 'submitted') {
		toolbarbg = $('.record-toolbar > .btn-group').first();

		editButton = $('.record-toolbar').find('.btn-primary').first();
		editButton.attr('disabled', 'disabled');

		toolbarbg.attr('title', 'Editing is not permitted while record is awaiting approval');
		toolbarbg.attr('data-toggle', 'tooltip');
		toolbarbg.attr('data-placement', 'top');
		toolbarbg.tooltip();
	    }

	    $('.registration-action-form .btn-cancel').on('click', function (event) {
		    event.stopImmediatePropagation();
		    event.preventDefault();
		    $('.registration-action').trigger("click");
		});

	    // Override the default bootstrap dropdown behaviour here to
	    // ensure that this modal stays open even when another modal is
	    // opened within it.
 	    $(".registration-action").on("click", function(event) {
 		    event.preventDefault();
 		    event.stopImmediatePropagation();

 		    if ($(this).attr('disabled')) {
 			return;
 		    }

 		    if ($(".registration-action-form")[0].style.display === "block") {
 			// Hide it
 			$(".registration-action-form").css("display", "");
 		    } else {
 			// Show it
 			$(".registration-action-form").css("display", "block");
 		    }
 		});

	    // Stop the modal from being hidden by clicks within the form
	    $(".registration-action-form").on("click", function(event) {
		    event.stopPropagation();
		});


	    $(".registration-action-form .add-event-button").on("click", function(event) {
		    event.stopPropagation();
		    event.preventDefault();

		    var url = AS.quickTemplate(decodeURIComponent($("#add-event-dropdown").data("add-event-url")), {event_type: $("#add_event_event_type").val()});
		    location.href = url;
		});
	};


	if (typeof REGISTRATION_ACTION_DROPDOWN !== 'undefined') {
	    init();
	}

});
