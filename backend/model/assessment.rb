class Assessment
  include ExternalIDs
  include AssessmentFromConservationRequest
  prepend AssessmentDisplayString
  include AssessmentSeries

  define_relationship(:name => :assessment,
                      :json_property => 'records',
                      :contains_references_to_types => proc {[PhysicalRepresentation]})


  def check_if_assessed?(physical_representation_qsa_ids)
    assessment_representation_ids = related_records(:assessment).select{|record| record.is_a?(PhysicalRepresentation)}.map{|record| record[:qsa_id]}
    (physical_representation_qsa_ids - assessment_representation_ids).empty?
  end

  def self.add_treatment_summaries_to_search_results(assessment_id, results)
    DB.open do |db|
      phys_rep_uri_to_ids = {}

      results.fetch('results', []).each do |result|
        uri = result['uri']
        parsed = JSONModel.parse_reference(uri)

        if parsed && parsed[:type] == 'physical_representation'
          phys_rep_uri_to_ids[uri] = parsed[:id]
        end
      end

      treatment_counts_by_physrep = {}

      db[:conservation_treatment]
        .join(:conservation_treatment_assessment_rlshp,
              Sequel.qualify(:conservation_treatment, :id) => Sequel.qualify(:conservation_treatment_assessment_rlshp, :conservation_treatment_id))
        .filter(Sequel.qualify(:conservation_treatment_assessment_rlshp, :assessment_id) => assessment_id)
        .group_and_count(Sequel.qualify(:conservation_treatment, :physical_representation_id),
                         Sequel.qualify(:conservation_treatment, :status))
        .each do |row|
        treatment_counts_by_physrep[row[:physical_representation_id]] ||= {}
        treatment_counts_by_physrep[row[:physical_representation_id]][row[:status]] ||= 0
        treatment_counts_by_physrep[row[:physical_representation_id]][row[:status]] += row[:count]
      end

      results.fetch('results', []).each do |result|
        physrep_id = phys_rep_uri_to_ids[result['uri']]
        next unless physrep_id

        result['treatments_summary'] = ASUtils.to_json(treatment_counts_by_physrep.fetch(physrep_id, {}))
      end
    end
  end
end
