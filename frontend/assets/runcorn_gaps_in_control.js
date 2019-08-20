(function(exports) {
  function RuncornGapsInControl($target, resourceId) {
    this.$target = $target;
    this.resourceId = resourceId;
    this.load();
  };

  RuncornGapsInControl.prototype.load = function() {
    var self = this;

    $.ajax({
      url: APP_PATH + 'resources/' + self.resourceId + '/gaps_in_control',
      type: 'get',
      dataType: 'html',
      success: function (html) {
        self.$target.html(html);
      }
    });
  };

  exports.RuncornGapsInControl = RuncornGapsInControl;
})(window);