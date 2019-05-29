(function() {
    function RepresentationFiles() {
        this.setupInputHandlers();
    }

    RepresentationFiles.prototype.setupInputHandlers = function () {
        var self = this;

        $(document).on('click', '.representation-file-upload', function (e) {
            var button = $(this);
            var buttonLabel = button.text();
            e.preventDefault();

            var fileInput = $('<input type="file" style="display: none;"></input>');

            button.attr('disabled', 'disabled');
            button.text('Uploading...')

            var restoreButton = function () {
                button.text(buttonLabel);
                button.attr('disabled', null);
                button.removeClass('btn-success').removeClass('btn-danger').addClass('btn-primary');
            };

            fileInput.on('change', function () {
                var promise = self.handleUpload(fileInput[0]);

                promise
                    .done(function (data) {
                        var key = data.key;
                        var mimeType = fileInput[0].files[0].type;

                        var link = button.closest('.form-group').find('.view-representation-file-link');
                        var hiddenKey = button.closest('.form-group').find('.representation-file-key-input');
                        var hiddenMimeType = button.closest('.form-group').find('.representation-file-mime-type-input');

                        // Slot in our key parameter
                        hiddenKey.val(key);
                        hiddenMimeType.val(mimeType);

                        var rewritten_href = link.attr('href').split('?')[0] + '?key=' + encodeURIComponent(key) + '&mime_type=' + encodeURIComponent(mimeType);
                        link.attr('href', rewritten_href);
                        link.show();

                        button.removeClass('btn-primary').addClass('btn-success').text('Upload successful')
                        setTimeout(restoreButton, 2000);
                    })
                    .fail(function () {
                        button.removeClass('btn-primary').addClass('btn-danger').text('Upload failed')
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


    window.RepresentationFiles = RepresentationFiles
}());
