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

  $('#runcornConfirmDownloadCSV', $modal).on('click', function() {
    $(this).prop('disabled', true);
    $('.downloading-message', $modal).removeClass('hide');

    // var $iframe = $('<iframe>');
    // $iframe.attr('src', self.$button.attr('href'));
    // $iframe.addClass('hide');
    // $modal.append($iframe);
    // $iframe[0].onerror = function() {
    //   $('.downloading-message', $modal).html('<span class="text-danger">Error downloading CSV.</span>');
    // };

    $(this).addClass('hide');
    $('#runcornDownloadCSVDone', $modal).removeClass('hide');

    window.location.href = self.$button.attr('href');
  });
};

$(document).ready(function() {
  if ($('#searchExport').length === 1) {
    new RuncornDownloadCSVWrapper($('#searchExport'));
  }
});