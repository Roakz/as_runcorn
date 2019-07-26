function ConservationRequestAssignRecords() {
    this.setupBinds();
}

ConservationRequestAssignRecords.prototype.addJSWonderment = function() {
    $('#representations_requested .table-record-actions .btn-group').each(function () {
        $(this).append($('<button class="btn btn-xs btn-danger representation-remove-btn">Remove</button>'));
    })
};

ConservationRequestAssignRecords.prototype.setupBinds = function() {
    $(document).on('click', '.representation-remove-btn', function (e) {
        e.preventDefault();

        var linker = $('#conservation_request_removes_linker');
        var json = $(this).closest('tr').data('resolved-record');

        var existing_entries = linker.tokenInput('get');

        if (existing_entries.map(function (entry) { return entry.id} ).indexOf(json.uri) >= 0) {
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
}

window.assign_records_form = new ConservationRequestAssignRecords();
