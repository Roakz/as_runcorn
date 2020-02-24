require 'csv'
require_relative 'runcorn_report'

class ConservationTreatmentsReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def to_stream
    Enumerator.new do |y|
      y << CSV.generate_line(['Conservation Requests (CR)',
                              'Assessment ID (AS)',
                              'Agency ID (A)',
                              'Series ID (S)',
                              'Series Title',
                              'Record ID (ITM)',
                              'Physical Representation ID (PR)',
                              'Format',
                              'Status',
                              'Treatment Process',
                              'Treatments Applied',
                              'Number of Treatments applied',
                              'Materials Used - Consumables',
                              'Materials Used - Staff Time',
                              'Date Conservation Required By',
                              'Date Commenced',
                              'Date Completed',
                              'Created By'])

      DB.open do |aspacedb|
        base_ds = aspacedb[:conservation_treatment]

        if @from_date
          from_time = @from_date.to_time
          base_ds = base_ds.where { Sequel.qualify(:conservation_treatment, :persistent_create_time) >= from_time }
        end

        if @to_date
          to_time = (@to_date + 1).to_time - 1
          base_ds = base_ds.where { Sequel.qualify(:conservation_treatment, :persistent_create_time) <= to_time }
        end

        responsible_agency_map = build_responsible_agency_map(base_ds)
        agency_qsa_ids = build_agency_qsa_id_map(aspacedb, responsible_agency_map)
        treatments_map = build_treatments_map(base_ds)

        base_ds
          .left_join(:conservation_treatment_assessment_rlshp, Sequel.qualify(:conservation_treatment_assessment_rlshp, :conservation_treatment_id) => Sequel.qualify(:conservation_treatment, :id))
          .left_join(:assessment, Sequel.qualify(:assessment, :id) => Sequel.qualify(:conservation_treatment_assessment_rlshp, :assessment_id))
          .left_join(:conservation_request_assessment_rlshp, Sequel.qualify(:conservation_request_assessment_rlshp, :assessment_id) => Sequel.qualify(:assessment, :id))
          .left_join(:conservation_request, Sequel.qualify(:conservation_request, :id) => Sequel.qualify(:conservation_request_assessment_rlshp, :conservation_request_id))
          .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:conservation_treatment, :physical_representation_id))
          .join(:resource, Sequel.qualify(:resource, :id) => Sequel.qualify(:physical_representation, :resource_id))
          .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
          .left_join(:conservation_treatment_user_rlshp, Sequel.qualify(:conservation_treatment_user_rlshp, :conservation_treatment_id) => Sequel.qualify(:conservation_treatment, :id))
          .left_join(:name_person, Sequel.qualify(:name_person, :agent_person_id) => Sequel.qualify(:conservation_treatment_user_rlshp, :agent_person_id), Sequel.qualify(:name_person, :is_display_name) => 1)
          .select(
              Sequel.qualify(:conservation_request_assessment_rlshp, :conservation_request_id),
              Sequel.as(Sequel.qualify(:assessment, :id), :assessment_id),
              Sequel.as(Sequel.qualify(:resource, :qsa_id), :series_qsa_id),
              Sequel.as(Sequel.qualify(:resource, :title), :series_title),
              Sequel.as(Sequel.qualify(:physical_representation, :qsa_id), :pr_qsa_id),
              Sequel.as(Sequel.qualify(:physical_representation, :format_id), :pr_format_id),
              Sequel.as(Sequel.qualify(:archival_object, :id), :archival_object_id),
              Sequel.as(Sequel.qualify(:archival_object, :qsa_id), :controlling_record_qsa_id),
              Sequel.as(Sequel.qualify(:conservation_treatment, :id), :conservation_treatment_id),
              Sequel.qualify(:conservation_treatment, :status),
              Sequel.qualify(:conservation_treatment, :treatment_process),
              Sequel.qualify(:conservation_treatment, :materials_used_consumables),
              Sequel.qualify(:conservation_treatment, :materials_used_staff_time),
              Sequel.qualify(:conservation_request, :date_required_by),
              Sequel.qualify(:conservation_treatment, :start_date),
              Sequel.qualify(:conservation_treatment, :end_date),
              Sequel.as(Sequel.qualify(:name_person, :sort_name), :created_by),
          )
          .order(
              Sequel.qualify(:conservation_request_assessment_rlshp, :conservation_request_id),
              Sequel.qualify(:assessment, :id)
          )
          .each do |row|
          y << CSV.generate_line([
            row[:conservation_request_id] ? QSAId.prefixed_id_for(ConservationRequest, row[:conservation_request_id]) : nil,
            row[:assessment_id] ? QSAId.prefixed_id_for(Assessment, row[:assessment_id]) : nil,
            agency_qsa_ids.fetch(responsible_agency_map.fetch(row[:archival_object_id]), nil),
            QSAId.prefixed_id_for(Resource, row[:series_qsa_id]),
            row[:series_title],
            QSAId.prefixed_id_for(ArchivalObject, row[:controlling_record_qsa_id]),
            QSAId.prefixed_id_for(PhysicalRepresentation, row[:pr_qsa_id]),
            BackendEnumSource.value_for_id('runcorn_format', row[:pr_format_id]),
            row[:status].gsub('_', ' '),
            row[:treatment_process],
            (treatments = treatments_map.fetch(row[:conservation_treatment_id], nil)) ? treatments.sort.join('; ') : nil,
            treatments_map.fetch(row[:conservation_treatment_id], []).length,
            row[:materials_used_consumables],
            row[:materials_used_staff_time],
            row[:date_required_by],
            row[:start_date],
            row[:end_date],
            row[:created_by],
          ])
        end
      end
    end
  end

  def build_responsible_agency_map(base_ds)
    result = {}

    repo_id = base_ds
                .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:conservation_treatment, :physical_representation_id))
                .select(:repo_id).first[:repo_id]

    RequestContext.open(:repo_id => repo_id) do
      ArchivalObject
        .filter(:id => base_ds
                         .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:conservation_treatment, :physical_representation_id))
                         .select(Sequel.qualify(:physical_representation, :archival_object_id)))
        .each do |ao|
        result[ao.id] = JSONModel::JSONModel(:agent_corporate_entity).id_for(ao.responsible_agency.fetch(:uri))
      end
    end

    result
  end

  def build_agency_qsa_id_map(aspacedb, responsible_agency_map)
    agency_ids = responsible_agency_map.values.uniq
    aspacedb[:agent_corporate_entity]
      .filter(:id => agency_ids)
      .select(:id, :qsa_id)
      .map do |row|
      [row[:id], QSAId.prefixed_id_for(AgentCorporateEntity, row[:qsa_id])]
    end.to_h
  end

  def build_treatments_map(base_ds)
    result = {}

    base_ds
      .join(:conservation_treatment_applied_treatment, Sequel.qualify(:conservation_treatment_applied_treatment, :conservation_treatment_id) => Sequel.qualify(:conservation_treatment, :id))
      .join(:assessment_attribute_definition, Sequel.qualify(:assessment_attribute_definition, :id) => Sequel.qualify(:conservation_treatment_applied_treatment, :assessment_attribute_definition_id))
      .select(Sequel.qualify(:conservation_treatment, :id),
              Sequel.qualify(:assessment_attribute_definition, :label))
      .map do |row|
      result[row[:id]] ||= []
      result[row[:id]] << row[:label]
    end

    result
  end
end
