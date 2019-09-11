function BulkActionFunctionalLocationUpdate(bulkContainerSearch) {
  this.bulkContainerSearch = bulkContainerSearch;
  this.MENU_ID = "bulkActionUpdateFunctionalLocation";

  this.setup_menu_item();
};


BulkActionFunctionalLocationUpdate.prototype.setup_update_form = function($modal) {
  var self = this;

  var $form = $modal.find("form");

  $(document).trigger("loadedrecordsubforms.aspace", [$form]);

  $form.on("submit", function(event) {
    event.preventDefault();
    self.perform_update($form, $modal);
  });
};


BulkActionFunctionalLocationUpdate.prototype.perform_update = function($form, $modal) {
  var self = this;

  $.ajax({
    url: AS.app_prefix("top_containers/bulk_operations/update_functional_location"),
    data: $form.serializeArray(),
    type: "post",
    success: function(html) {
      $form.replaceWith(html);
      $modal.trigger("resize");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      var error = AS.renderTemplate("template_bulk_operation_error_message", {message: jqXHR.responseText});
      $('#alertBucket').replaceWith(error);
    }
  });
};

BulkActionFunctionalLocationUpdate.prototype.setup_menu_item = function() {
  var self = this;

  self.$menuItem = $("#" + self.MENU_ID, self.bulkContainerSearch.$toolbar);

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionFunctionalLocationUpdate.prototype.show = function() {
  var dialog_content = AS.renderTemplate("bulk_action_update_functional_location", {
    selection: this.bulkContainerSearch.get_selection()
  });

  var $modal = AS.openCustomModal("bulkUpdateModal", this.$menuItem[0].text, dialog_content, 'full');

  this.setup_update_form($modal);
};


function BulkContainerSearchExtras($search_form, $results_container, $toolbar) {
    this.$search_form = $search_form;
    this.$results_container = $results_container;
    this.$toolbar = $toolbar;
}

BulkContainerSearchExtras.prototype.get_selection = function() {
    var self = this;
    var results = [];

    self.$results_container.find("tbody :checkbox:checked").each(function(i, checkbox) {
	    results.push({
		    uri: checkbox.value,
			display_string: $(checkbox).data("display-string"),
			row: $(checkbox).closest("tr")
			});
	});

    return results;
};


$(function() {
  var bulkContainerSearchExtras = new BulkContainerSearchExtras($("#bulk_operation_form"),
								$("#bulk_operation_results"),
								$(".record-toolbar.bulk-operation-toolbar"));

  new BulkActionFunctionalLocationUpdate(bulkContainerSearchExtras);
});
