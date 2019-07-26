module ConservationRequests

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      backlink_col = :"#{self.table_name}_id"

      representation_to_conservation_request = {}

      db[:conservation_request_representations].filter(backlink_col => objs.map(&:id)).select(:conservation_request_id, backlink_col).each do |row|
        representation_to_conservation_request[row[backlink_col]] ||= []
        representation_to_conservation_request[row[backlink_col]] << row[:conservation_request_id]
      end

      objs.zip(jsons).each do |obj, json|
        json[:conservation_requests] = representation_to_conservation_request.fetch(obj.id, []).map {|conservation_request_id|
          {'ref' => JSONModel(:conservation_request).uri_for(conservation_request_id, :repo_id => RequestContext.get(:repo_id))}
        }
      end

      jsons
    end

  end

end
