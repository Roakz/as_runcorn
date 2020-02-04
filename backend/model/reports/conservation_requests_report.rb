require 'csv'
require_relative 'runcorn_report'

class ConservationRequestsReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def to_stream
    tempfile = Tempfile.new('ConservationRequestsReport')

    CSV.open(tempfile, 'w') do |csv|
      csv << ['Conservation Requests (CR)',
              'Series ID (S)',
              'Series Title ',
              'Status',
              'Assessment (AS)',
              'Date of Request',
              'Requested By',
              'Requested For',
              'Reason Requested',
              'Client Type',
              'Date Conservation Required By',
              'Number of items']

      DB.open do |aspacedb|
        base_ds = aspacedb[:conservation_request]

        if @from_date
          from_time = @from_date.to_time.to_i * 1000
          base_ds = base_ds.where { Sequel.qualify(:conservation_request, :create_time) >= from_time }
        end

        if @to_date
          to_time = (@to_date + 1).to_time.to_i * 1000 - 1
          base_ds = base_ds.where { Sequel.qualify(:conservation_request, :create_time) <= to_time }
        end

        resource_map = build_cr_to_resources_map(base_ds)

        base_ds
          .left_join(:conservation_request_assessment_rlshp, Sequel.qualify(:conservation_request_assessment_rlshp, :conservation_request_id) => Sequel.qualify(:conservation_request, :id))
          .left_join(:assessment, Sequel.qualify(:assessment, :id) => Sequel.qualify(:conservation_request_assessment_rlshp, :assessment_id))
          .order(Sequel.qualify(:conservation_request, :id))
          .select(Sequel.qualify(:conservation_request, :id),
                  Sequel.qualify(:conservation_request, :status_id),
                  Sequel.as(Sequel.qualify(:assessment, :id), :assessment_id),
                  Sequel.qualify(:conservation_request, :date_of_request),
                  Sequel.qualify(:conservation_request, :requested_by),
                  Sequel.qualify(:conservation_request, :requested_for_id),
                  Sequel.qualify(:conservation_request, :reason_requested_id),
                  Sequel.qualify(:conservation_request, :client_type_id),
                  Sequel.qualify(:conservation_request, :date_required_by),
                  )
          .each do |cr_row|
          if resource_map.include?(cr_row[:id])
            resource_map.fetch(cr_row[:id], []).each do |resource_data|
              csv << [
                QSAId.prefixed_id_for(ConservationRequest, cr_row[:id]),
                resource_data.fetch(:qsa_id),
                resource_data.fetch(:title),
                BackendEnumSource.value_for_id('conservation_request_status', cr_row[:status_id]),
                QSAId.prefixed_id_for(Assessment, cr_row[:assessment_id]),
                cr_row[:date_of_request],
                cr_row[:requested_by],
                BackendEnumSource.value_for_id('conservation_request_requested_for', cr_row[:requested_for_id]),
                BackendEnumSource.value_for_id('conservation_request_reason', cr_row[:reason_requested_id]),
                BackendEnumSource.value_for_id('conservation_request_client_type', cr_row[:client_type_id]),
                cr_row[:date_required_by],
                resource_data.fetch(:count),
              ]
            end
          else
            # no linked records
            csv << [
              QSAId.prefixed_id_for(ConservationRequest, cr_row[:id]),
              nil,
              nil,
              BackendEnumSource.value_for_id('conservation_request_status', cr_row[:status_id]),
              QSAId.prefixed_id_for(Assessment, cr_row[:assessment_id]),
              cr_row[:date_of_request],
              cr_row[:requested_by],
              BackendEnumSource.value_for_id('conservation_request_requested_for', cr_row[:requested_for_id]),
              BackendEnumSource.value_for_id('conservation_request_reason', cr_row[:reason_requested_id]),
              BackendEnumSource.value_for_id('conservation_request_client_type', cr_row[:client_type_id]),
              cr_row[:date_required_by],
              '0'
            ]
          end
        end
      end
    end

    tempfile.rewind
    tempfile
  end

  def build_cr_to_resources_map(base_ds)
    result = {}

    base_ds
      .join(:conservation_request_representations, Sequel.qualify(:conservation_request_representations, :conservation_request_id) => Sequel.qualify(:conservation_request, :id))
      .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:conservation_request_representations, :physical_representation_id))
      .join(:resource, Sequel.qualify(:resource, :id) => Sequel.qualify(:physical_representation, :resource_id))
      .group_and_count(Sequel.qualify(:conservation_request, :id),
                       Sequel.qualify(:physical_representation, :resource_id),
                       Sequel.qualify(:resource, :qsa_id),
                       Sequel.qualify(:resource, :title))
      .each do |row|
        result[row[:id]] ||= []
        result[row[:id]] << {
            :count => row[:count],
            :qsa_id => QSAId.prefixed_id_for(Resource, row[:qsa_id]),
            :title => row[:title],
        }
    end

    result
  end
end
