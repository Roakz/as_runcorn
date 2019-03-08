$(document).on("loadedrecordform.aspace", function(event) {
    var for_attr = QSA_ID_MODEL + '_' + QSA_ID_EXISTING_ID + '_';
    $('label[for=' + for_attr + ']').closest('.form-group').hide();
});
