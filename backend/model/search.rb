class Search

  def self.search_csv( params, repo_id )
    criteria = params.map{|k, v| [k.intern, v]}.to_h

    criteria.delete(:facet)
    criteria.delete(:modified_since)
    criteria[:dt] = "json"
    criteria[:page] = 1
    criteria[:page_size] = 50

    if criteria.has_key?(:type) && criteria[:type].length == 1 && criteria[:type][0] == 'agent'
      CsvExportAgents.new(criteria, repo_id).to_csv
    elsif criteria.has_key?(:type) && criteria[:type].length == 1 && criteria[:type][0] == 'function'
      CsvExportFunctions.new(criteria, repo_id).to_csv
    elsif criteria.has_key?(:type) && criteria[:type].length == 1 && criteria[:type][0] == 'mandate'
      CsvExportMandates.new(criteria, repo_id).to_csv
    elsif criteria.has_key?(:type) && criteria[:type].length == 1 && criteria[:type][0] == 'resource'
      CsvExportSeries.new(criteria, repo_id).to_csv
    elsif criteria.has_key?(:type) && criteria[:type].length == 1 && criteria[:type][0] == 'archival_object'
      CsvExportItems.new(criteria, repo_id).to_csv
    elsif criteria.has_key?(:type) && criteria[:type].length == 2 && criteria[:type].sort[0] == 'digital_representation' && criteria[:type].sort[1] == 'physical_representation'
      CsvExportRepresentations.new(criteria, repo_id).to_csv
    else
      CsvExport.new(criteria, repo_id).to_csv
    end
  end

end