require 'csv'
require_relative 'runcorn_report'

class AssessmentsReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def to_stream
    tempfile = Tempfile.new('AssessmentsReport')

    CSV.open(tempfile, 'w') do |csv|
      csv << ['Assessment ID (AS)',
              'Series ID (S)/Title',
              'Status',
              'Survey Start',
              'Survey End',
              'Treatment Priority',
              'Treatment Summary',
              'Proposed Treatments',
              'Time it took to Complete Survey',
              'Number of items']

      DB.open do |aspacedb|
        base_ds = aspacedb[:assessment]

        if @from_date
          from_time = @from_date.to_time
          base_ds = base_ds.where { Sequel.qualify(:assessment, :create_time) >= from_time }
        end

        if @to_date
          to_time = (@to_date + 1).to_time - 1
          base_ds = base_ds.where { Sequel.qualify(:assessment, :create_time) <= to_time }
        end

        resource_map = build_assessment_to_resources_map(base_ds)
        treatment_counts_map = build_treatment_counts_map(base_ds)
        conservation_issues_map = build_conservation_issues_map(base_ds)

        base_ds
          .left_join(:conservation_request_assessment_rlshp, Sequel.qualify(:conservation_request_assessment_rlshp, :assessment_id) => Sequel.qualify(:assessment, :id))
          .left_join(:conservation_request, Sequel.qualify(:conservation_request, :id) => Sequel.qualify(:conservation_request_assessment_rlshp, :conservation_request_id))
          .select(Sequel.qualify(:assessment, :id),
                  Sequel.qualify(:conservation_request, :status_id),
                  Sequel.qualify(:assessment, :survey_begin),
                  Sequel.qualify(:assessment, :survey_end),
                  Sequel.qualify(:assessment, :treatment_priority_id),
                  Sequel.qualify(:assessment, :surveyed_duration),
                  )
          .each do |row|

          if resource_map.include?(row[:id])
            resource_map.fetch(row[:id]).each do |resource_data|
              treatment_summary = nil

              if (treatment_data = treatment_counts_map.dig(row[:id], resource_data.fetch(:id)))
                treatment_summary = treatment_data.map {|status, count| '%d %s' % [count, status.gsub('_', ' ')]}.join('; ')
              end

              csv << [
                QSAId.prefixed_id_for(Assessment, row[:id]),
                '%s %s' % [resource_data.fetch(:qsa_id), resource_data.fetch(:title)],
                BackendEnumSource.value_for_id('conservation_request_status', row[:status_id]),
                row[:survey_begin],
                row[:survey_end],
                BackendEnumSource.value_for_id('runcorn_treatment_priority', row[:treatment_priority_id]),
                treatment_summary,
                conservation_issues_map.fetch(row[:id], false) ? conservation_issues_map.fetch(row[:id]).join('; ') : nil,
                row[:surveyed_duration],
                resource_data.fetch(:count)
              ]
            end
          else
            # no items linked to assessment
            csv << [
              QSAId.prefixed_id_for(Assessment, row[:id]),
              nil,
              BackendEnumSource.value_for_id('conservation_request_status', row[:status_id]),
              row[:survey_begin],
              row[:survey_end],
              BackendEnumSource.value_for_id('runcorn_treatment_priority', row[:treatment_priority_id]),
              nil,
              conservation_issues_map.fetch(row[:id], false) ? conservation_issues_map.fetch(row[:id]).join('; ') : nil,
              row[:surveyed_duration],
              nil
            ]
          end
        end
      end
    end

    tempfile.rewind
    tempfile
  end

  def build_assessment_to_resources_map(base_ds)
    result = {}

    base_ds
        .join(:assessment_rlshp, Sequel.qualify(:assessment_rlshp, :assessment_id) => Sequel.qualify(:assessment, :id))
        .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:assessment_rlshp, :physical_representation_id))
        .join(:resource, Sequel.qualify(:resource, :id) => Sequel.qualify(:physical_representation, :resource_id))
        .group_and_count(Sequel.qualify(:assessment, :id),
                         Sequel.qualify(:physical_representation, :resource_id),
                         Sequel.qualify(:resource, :qsa_id),
                         Sequel.qualify(:resource, :title))
        .each do |row|
      result[row[:id]] ||= []
      result[row[:id]] << {
          :id => row[:resource_id],
          :count => row[:count],
          :qsa_id => QSAId.prefixed_id_for(Resource, row[:qsa_id]),
          :title => row[:title],
      }
    end

    result
  end

  def build_conservation_issues_map(base_ds)
    result = {}

    base_ds
      .join(:assessment_attribute, Sequel.qualify(:assessment_attribute, :assessment_id) => Sequel.qualify(:assessment, :id))
      .join(:assessment_attribute_definition, Sequel.qualify(:assessment_attribute_definition, :id) => Sequel.qualify(:assessment_attribute, :assessment_attribute_definition_id))
      .filter(Sequel.qualify(:assessment_attribute, :value) => 'true')
      .filter(Sequel.qualify(:assessment_attribute_definition, :type) => 'conservation_issue')
      .select(Sequel.qualify(:assessment, :id),
              Sequel.qualify(:assessment_attribute_definition, :label))
      .each do |row|
      result[row[:id]] ||= []
      result[row[:id]] << row[:label]
    end

    result
  end

  def build_treatment_counts_map(base_ds)
    result = {}

    base_ds
      .join(:assessment_rlshp, Sequel.qualify(:assessment_rlshp, :assessment_id) => Sequel.qualify(:assessment, :id))
      .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:assessment_rlshp, :physical_representation_id))
      .join(:conservation_treatment, Sequel.qualify(:conservation_treatment, :physical_representation_id) => Sequel.qualify(:physical_representation, :id))
      .group_and_count(Sequel.qualify(:assessment, :id),
                       Sequel.qualify(:physical_representation, :resource_id),
                       Sequel.qualify(:conservation_treatment, :status))
      .each do |row|
      result[row[:id]] ||= {}
      result[row[:id]][row[:resource_id]] ||= {}
      result[row[:id]][row[:resource_id]][row[:status]] = row[:count]
    end

    result
  end
end
