module SeriesRepresentationMetadata

  extend JSONModel

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      p [Time.now, "START", "prepare_counts"]
      representations_counts = prepare_counts(objs)
      p [Time.now, "END", "prepare_counts"]
      p [Time.now, "START", "prepare_conservation_status"]
      conservation_status = prepare_conservation_status(objs)
      p [Time.now, "END", "prepare_conservation_status"]

      objs.zip(jsons).each do |obj, json|
        json['physical_representations_count'] = representations_counts.fetch(obj.id, {}).fetch('physical_representations_count', 0)
        json['digital_representations_count'] = representations_counts.fetch(obj.id, {}).fetch('digital_representations_count', 0)
        json['significant_representations_counts'] = representations_counts.fetch(obj.id, {}).fetch('significant_representations_counts')
        json['has_conservation_treatments_awaiting'] = conservation_status.fetch(obj.id, false)
      end

      jsons
    end


    def default_significance_counts
      @default_significance_counts ||= BackendEnumSource.values_for('runcorn_significance').reject{|sig| sig == 'standard'}.map{|sig| [sig, 0]}.to_h
    end


    def prepare_conservation_status(objs)
      Hash[DB.open do |db|
        db[:resource]
          .inner_join(:archival_object, Sequel.qualify(:archival_object, :root_record_id) => Sequel.qualify(:resource, :id))
          .inner_join(:physical_representation, Sequel.qualify(:physical_representation, :archival_object_id) => Sequel.qualify(:archival_object, :id))
          .inner_join(:conservation_treatment, Sequel.qualify(:conservation_treatment, :physical_representation_id) => Sequel.qualify(:physical_representation, :id))
          .filter(Sequel.qualify(:resource, :id) => objs.map(&:id))
          .filter(Sequel.~(Sequel.qualify(:conservation_treatment, :status) => 'completed'))
          .distinct(Sequel.qualify(:resource, :id))
          .select(Sequel.qualify(:resource, :id))
          .map {|row|
            [row[:id], true]
          }
      end]
    end


    def prepare_counts(objs)
      result = {}

      node_type_backlink_col = :"#{self.node_model.table_name}_id"

      root_ids = objs.map(&:id)

      node_physical_representation_counts = {}
      node_digital_representation_counts = {}

      p [Time.now, "START", "prepare_counts:1"]
      query = PhysicalRepresentation
        .left_join(:deaccession, Sequel.qualify(:deaccession, :physical_representation_id) => Sequel.qualify(:physical_representation, :id))
        .left_join(:enumeration_value, Sequel.qualify(:enumeration_value, :id) => Sequel.qualify(:physical_representation, :significance_id))
        .filter(Sequel.qualify(PhysicalRepresentation.table_name, :resource_id) => root_ids)
        .filter(Sequel.qualify(:deaccession, :id) => nil)
        .group_and_count(Sequel.qualify(:physical_representation, :resource_id),
                         Sequel.qualify(:enumeration_value, :value))

        p query

       query.each do |row|

        node_physical_representation_counts[row[:root_record_id]] ||= default_significance_counts.merge({:total => 0})
        node_physical_representation_counts[row[:root_record_id]][:total] += row[:count]
        node_physical_representation_counts[row[:root_record_id]][row[:value]] = row[:count] unless row[:value].nil? || row[:value] == 'standard'
      end
      p [Time.now, "END", "prepare_counts:1"]

      p [Time.now, "START", "prepare_counts:2"]
      query = DigitalRepresentation
        .left_join(:deaccession, Sequel.qualify(:deaccession, :digital_representation_id) => Sequel.qualify(:digital_representation, :id))
        .filter(Sequel.qualify(DigitalRepresentation.table_name, :resource_id) => root_ids)
        .filter(Sequel.qualify(:deaccession, :id) => nil)
        .group_and_count(Sequel.qualify(:digital_representation, :resource_id))

        p query
  
       query.each do |row|
        node_digital_representation_counts[row[:root_record_id]] = row[:count]
      end
      p [Time.now, "END", "prepare_counts:2"]

      p [Time.now, "START", "prepare_counts:to_process"]
      to_process = self.node_model
                     .filter(:root_record_id => root_ids)
                     .inner_join(:deaccession, Sequel.qualify(:deaccession, :archival_object_id) => Sequel.qualify(:archival_object, :id))
                     .select(Sequel.qualify(:archival_object, :id))
      p [Time.now, "END", "prepare_counts:to_process"]

      p [Time.now, "START", "prepare_counts:loop"]
      while(!to_process.empty?)
        PhysicalRepresentation
          .inner_join(self.node_model.table_name, Sequel.qualify(PhysicalRepresentation.table_name, node_type_backlink_col) => Sequel.qualify(self.node_model.table_name, :id))
          .left_join(:deaccession, Sequel.qualify(:deaccession, :physical_representation_id) => Sequel.qualify(:physical_representation, :id))
          .left_join(:enumeration_value, Sequel.qualify(:enumeration_value, :id) => Sequel.qualify(:physical_representation, :significance_id))
          .filter(Sequel.qualify(PhysicalRepresentation.table_name, node_type_backlink_col) => to_process)
          .filter(Sequel.qualify(:deaccession, :id) => nil)
          .group_and_count(Sequel.qualify(self.node_model.table_name, :root_record_id),
                           Sequel.qualify(:enumeration_value, :value)).each do |row|

          node_physical_representation_counts[row[:root_record_id]][:total] -= row[:count]
          node_physical_representation_counts[row[:root_record_id]][row[:value]] -= row[:count] unless row[:value].nil? || row[:value] == 'standard'
        end

        DigitalRepresentation
          .inner_join(self.node_model.table_name, Sequel.qualify(DigitalRepresentation.table_name, node_type_backlink_col) => Sequel.qualify(self.node_model.table_name, :id))
          .left_join(:deaccession, Sequel.qualify(:deaccession, :digital_representation_id) => Sequel.qualify(:digital_representation, :id))
          .filter(Sequel.qualify(DigitalRepresentation.table_name, node_type_backlink_col) => to_process)
          .filter(Sequel.qualify(:deaccession, :id) => nil)
          .group_and_count(Sequel.qualify(self.node_model.table_name, :root_record_id)).each do |row|
          node_digital_representation_counts[row[:root_record_id]] -= row[:count]
        end

        to_process = ArchivalObject.filter(:parent_id => to_process).select(:id)
      end
      p [Time.now, "END", "prepare_counts:loop"]

      objs.each do |obj|
        result[obj.id] = {
          'physical_representations_count' => node_physical_representation_counts.fetch(obj.id, {:total => 0})[:total],
          'digital_representations_count' => node_digital_representation_counts.fetch(obj.id, 0),
          'significant_representations_counts' => node_physical_representation_counts.fetch(obj.id, default_significance_counts).reject{|k,v| k == :total}
        }
      end

      result
    end
  end
end
