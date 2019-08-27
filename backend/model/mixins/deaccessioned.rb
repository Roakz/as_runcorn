module Deaccessioned

  def self.included(base)
    base.extend(ClassMethods)
  end

  def self.build_deaccessioned_map(ao_ids)
    deaccession_map = {}
    parent_map = {}

    ArchivalObject
      .join(:resource, Sequel.qualify(:resource, :id) => Sequel.qualify(:archival_object, :root_record_id))
      .left_join(Sequel.as(:deaccession, :deaccession_resource),
                 Sequel.qualify(:deaccession_resource, :resource_id) => Sequel.qualify(:resource, :id))
      .left_join(Sequel.as(:deaccession, :deaccession_ao),
                 Sequel.qualify(:deaccession_ao, :archival_object_id) => Sequel.qualify(:archival_object, :id))
      .filter(Sequel.qualify(:archival_object, :id) => ao_ids)
      .select(Sequel.qualify(:archival_object, :id),
              Sequel.qualify(:archival_object, :parent_id),
              Sequel.as(Sequel.qualify(:deaccession_resource, :id), :resource_deaccession_id),
              Sequel.as(Sequel.qualify(:deaccession_ao, :id), :ao_deaccession_id))
      .each do |row|
      deaccession_map[row[:id]] = !!(row[:resource_deaccession_id] || row[:ao_deaccession_id])
      parent_map[row[:id]] = row[:parent_id]
    end

    if deaccession_map.values.any? {|val| !val}
      # up the tree we go!
      ids_to_process = parent_map.values.compact.uniq
      while(!ids_to_process.empty?) do
        next_ids_to_process = []
        ArchivalObject
          .left_join(Sequel.as(:deaccession, :deaccession_ao),
                     Sequel.qualify(:deaccession_ao, :archival_object_id) => Sequel.qualify(:archival_object, :id))
          .filter(Sequel.qualify(:archival_object, :id) => ids_to_process)
          .select(Sequel.qualify(:archival_object, :id),
                  Sequel.qualify(:archival_object, :parent_id),
                  Sequel.as(Sequel.qualify(:deaccession_ao, :id), :ao_deaccession_id))
          .each do |row|
          parent_map[row[:id]] = row[:parent_id]

          if row[:ao_deaccession_id]
            deaccession_map[row[:id]] = true
          else
            next_ids_to_process << row[:parent_id]
          end
        end

        ids_to_process = next_ids_to_process.compact.uniq
      end
    end

    Hash[ao_ids.map {|ao_id|
           current = ao_id
           deaccessioned = false

           while(current && !deaccessioned) do
             deaccessioned = deaccession_map.fetch(current)
             current = parent_map[current]
           end

           [ao_id, deaccessioned]
         }]
  end


  def deaccessioned?
    return true if !self.deaccession.empty?

    if self.class.is_a?(ArchivalObject)
      if self.parent_id
        ArchivalObject[self.parent_id].deaccessioned?
      else
        Resource[self.root_record_id].deaccessioned?
      end
    else
      false
    end
  end

  def deaccession!
    if self.class.is_a?(ArchivalObject)
      PhysicalRepresentation
        .filter(:archival_object_id => self.id)
        .each do |rep|
        rep.deaccession!
      end
    end

    self.children.each(&:deaccession!)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      if self == ArchivalObject
        # Precompute!
        deaccessioned_map = Deaccessioned.build_deaccessioned_map(objs.map(&:id))
      else
        deaccessioned_map = {}
      end

      objs.zip(jsons).each do |obj, json|
        json['deaccessioned'] = deaccessioned_map.fetch(obj.id, nil) || obj.deaccessioned?
      end

      jsons
    end
  end

end
