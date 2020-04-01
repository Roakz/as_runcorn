function RuncornDownloadCSVWrapper($button) {
  this.$button = $button;
  this.setup();
}

RuncornDownloadCSVWrapper.prototype.setup = function() {
  var self = this;
  self.$button.on('click', function(event) {
    event.preventDefault();

    self.openPopup();
  });
};

RuncornDownloadCSVWrapper.prototype.openPopup = function() {
  var self = this;
  var $content = $(AS.renderTemplate('runcornDownloadCSVPopupTemplate'));
  var $modal = AS.openCustomModal('runcornDownloadCSVPopup', 'Download CSV', $content.html(), false, {keyboard: false}, self.$button);
  var $selected = $('#tabledSearchResults .multiselect-column :checkbox:checked');

  if ($selected.length > 0) {
    $modal.find('.download-csv-total-hits').html($selected.length);
  }

  $('#runcornConfirmDownloadCSV', $modal).on('click', function() {
    $(this).prop('disabled', true);
    $('.downloading-message', $modal).removeClass('hide');
    $(this).addClass('hide');
    $('#runcornDownloadCSVDone', $modal).removeClass('hide');

    var targetURL = self.$button.attr('href');

    if ($selected.length > 0) {
      var query  = {
        op: 'OR',
        jsonmodel_type: 'boolean_query',
        subqueries: []
      };
      $selected.each(function() {
        var subquery = {
          field: 'id',
          value: $(this).val(),
          literal: true,
          comparator: 'equals',
          jsonmodel_type: 'field_query'
        };

        query.subqueries.push(subquery);
      });
      if (targetURL.indexOf('?') < 0) {
        targetURL += '?';
      } else {
        targetURL += '&';
      }
      targetURL += 'aq=' + encodeURIComponent(JSON.stringify({query: query}));
    }

    window.location.href = targetURL;
  });
};

$(document).ready(function() {
  if ($('#searchExport').length === 1) {
    new RuncornDownloadCSVWrapper($('#searchExport'));
  }
});