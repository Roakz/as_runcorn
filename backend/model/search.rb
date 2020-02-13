class Search
  require_relative 'csv_exports/base_csv_export'

  def self.search_csv( params, repo_id )
    criteria = params.map{|k, v| [k.intern, v]}.to_h

    criteria.delete(:facet)
    criteria.delete(:modified_since)
    criteria[:dt] = "json"
    criteria[:page] = 1
    criteria[:page_size] = 50

    BaseCSVExport.new(criteria, repo_id).to_csv
  end

end