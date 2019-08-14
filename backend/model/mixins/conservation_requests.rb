module ConservationRequests

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      backlink_col = :"#{self.table_name}_id"

      representation_to_conservation_request = {}

      db[:conservation_request_representations]
        .join(:conservation_request, Sequel.qualify(:conservation_request, :id) => Sequel.qualify(:conservation_request_representations, :conservation_request_id))
        .join(Sequel.as(:enumeration_value, :conservation_request_status), Sequel.qualify(:conservation_request_status, :id) => Sequel.qualify(:conservation_request, :status_id))
        .filter(backlink_col => objs.map(&:id))
        .select(Sequel.qualify(:conservation_request_representations, :conservation_request_id),
                Sequel.qualify(:conservation_request_representations, backlink_col),
                Sequel.as(Sequel.qualify(:conservation_request_status, :value), :status))
        .each do |row|
        representation_to_conservation_request[row[backlink_col]] ||= []
        representation_to_conservation_request[row[backlink_col]] << {
          id: row[:conservation_request_id],
          status: row[:status],
        }
      end

      objs.zip(jsons).each do |obj, json|
        json[:conservation_requests] = representation_to_conservation_request.fetch(obj.id, []).map {|conservation_request_blob|
          { 
            'ref' => JSONModel(:conservation_request).uri_for(conservation_request_blob.fetch(:id), :repo_id => RequestContext.get(:repo_id)),
            'status' => conservation_request_blob.fetch(:status),
          }
        }
      end

      jsons
    end

  end

end
