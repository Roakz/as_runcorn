module ResourcePublishable

  def self.included(base)
    base.extend(ClassMethods)
  end

  def rap_publishable?
    self.class.calculate_unpublishable([self.id]).empty?
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      unpublishable_resource_ids = calculate_unpublishable(objs.map(&:id))

      objs.zip(jsons).each do |obj, json|
        json['publishable'] = !unpublishable_resource_ids.include?(obj.id)
      end

      jsons
    end

    def calculate_unpublishable(ids)
      unpublishable_ids = ids

      unpublishable_ids -= db[:rap]
                            .filter(:resource_id => ids)
                            .filter(:open_access_metadata => 1)
                            .select(:resource_id)
                            .map{|row| row[:resource_id]}

      unpublishable_ids - db[:rap_applied]
                            .join(:rap, Sequel.qualify(:rap, :id) => Sequel.qualify(:rap_applied, :rap_id))
                            .filter(:root_record_id => unpublishable_ids)
                            .filter(Sequel.qualify(:rap, :open_access_metadata) => 1)
                            .select(:root_record_id)
                            .map{|row| row[:root_record_id]}
    end
  end
end