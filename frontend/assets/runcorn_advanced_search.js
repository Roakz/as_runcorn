(function () {
    var set_placeholder = function(row, index, from_placeholder, to_placeholder) {
        row.find('#vf' + index).attr('placeholder', from_placeholder);
        row.find('#vt' + index).attr('placeholder', to_placeholder);
    };

    $(document).bind('initadvancedsearchrow.aspace', function (event, field_data, row) {
        if (field_data.type === 'range') {
            if (field_data.query.field === 'start_date' || field_data.query.field === 'end_date') {
                set_placeholder(row, field_data.index, 'From (YYYY, YYYY-MM, YYYY-MM-DD)', 'To (YYYY, YYYY-MM, YYYY-MM-DD)');
            } else {
                set_placeholder(row, field_data.index, 'From', 'To');
            }
        }

        row.find('select#f' + field_data.index).on('change', function (e) {
            if (e.target.value == 'start_date' || e.target.value == 'end_date') {
                set_placeholder(row, field_data.index, 'From (YYYY, YYYY-MM, YYYY-MM-DD)', 'To (YYYY, YYYY-MM, YYYY-MM-DD)');
            } else {
                set_placeholder(row, field_data.index, 'From', 'To');
            }
        });

        if (typeof field_data.query.field === 'undefined') {
            row.find('select#f' + field_data.index).trigger('change');
        }
    });
}());
