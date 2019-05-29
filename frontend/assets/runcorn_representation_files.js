(function() {
    function RepresentationFiles() {
        this.setupInputHandlers();
        this.render();
    }

    RepresentationFiles.prototype.render = function () {
        $('.representation-file-widget').each(function () {
            var container = $(this);

            container.find('button').attr('disabled', null).hide();

            if (container.find('.representation-file-key-input').val()) {
                var label = container.find('.representation-file-replace-label').text();
                container.find('.representation-file-upload').text(label).show();
                container.find('.representation-file-clear').show();
            } else {
                var label = container.find('.representation-file-upload-label').text();
                container.find('.representation-file-upload').text(label).show();
                container.find('.representation-file-upload-new').show();
            }
        });
    };

    RepresentationFiles.prototype.setupInputHandlers = function () {
        var self = this;

        $(document).on('click', '.representation-file-clear', function (e) {
            e.preventDefault();
            var button = $(this);

            var link = button.closest('.form-group').find('.view-representation-file-link');
            var hiddenKey = button.closest('.form-group').find('.representation-file-key-input');
            var hiddenMimeType = button.closest('.form-group').find('.representation-file-mime-type-input');

            link.hide();
            hiddenKey.val(null);
            hiddenMimeType.val(null);

            self.render();
        });

        $(document).on('click', '.representation-file-upload', function (e) {
            e.preventDefault();
            var button = $(this);
            var buttonLabel = button.text();
            var container = button.closest('.form-group');

            var fileInput = $('<input type="file" style="display: none;"></input>');

            var restoreButton = function () {
                container.find('.representation-file-upload').removeClass('btn-success').removeClass('btn-danger').addClass('btn-primary');
                self.render();
            };

            fileInput.on('change', function () {
                button.attr('disabled', 'disabled');
                button.text(container.find('.representation-file-uploading-label').text());

                var promise = self.handleUpload(fileInput[0]);

                promise
                    .done(function (data) {
                        var key = data.key;
                        var mimeType = fileInput[0].files[0].type;

                        var link = container.find('.view-representation-file-link');
                        var hiddenKey = container.find('.representation-file-key-input');
                        var hiddenMimeType = container.find('.representation-file-mime-type-input');

                        // Slot in our key parameter
                        hiddenKey.val(key);
                        hiddenMimeType.val(mimeType);

                        var rewritten_href = link.attr('href').split('?')[0] + '?key=' + encodeURIComponent(key) + '&mime_type=' + encodeURIComponent(mimeType);
                        link.attr('href', rewritten_href);
                        link.show();

                        self.render();

                        container.find('.representation-file-upload:visible').removeClass('btn-primary').addClass('btn-success').text('Upload successful');
                        setTimeout(restoreButton, 2000);
                    })
                    .fail(function () {
                        button.removeClass('btn-primary').addClass('btn-danger').text('Upload failed');
                        setTimeout(restoreButton, 2000);
                    });
            });

            $(document.body).append(fileInput);
            fileInput.click();

            return false;
        });
    };

    RepresentationFiles.prototype.handleUpload = function (fileInput) {
        var formData = new FormData();
        formData.append('file', fileInput.files[0]);

        return $.ajax({
            type: "POST",
            url: AS.app_prefix('/representations/upload_file'),
            data: formData,
            processData: false,
            contentType: false,
        });
    };


    window.RepresentationFiles = RepresentationFiles;
}());
