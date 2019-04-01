class RepositoriesController
  private

  def handle_crud(opts)
    ensure_agency_existence_dates_are_valid(opts)
    super
  end

  def ensure_agency_existence_dates_are_valid(opts)
    # update
    if opts[:obj]

    # new
    else
      params[:repository][:agent_representation][:dates_of_existence] = [{
        jsonmodel_type: 'date',
        label: 'existence',
        date_type: 'inclusive',
        begin: Date.today.iso8601,
      }]
    end
  end
end