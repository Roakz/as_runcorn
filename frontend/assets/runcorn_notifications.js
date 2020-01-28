$(function() {
    function RuncornNotifications() {
        this.$container = $('#runcorn-notifications');
        this.load();
    }

    RuncornNotifications.prototype.load = function() {
        var self = this;
        $.ajax({
            url: APP_PATH + 'runcorn_notifications',
            success: function (html) {
                self.$container.html(html);
            }
        });
    }

    new RuncornNotifications();
});