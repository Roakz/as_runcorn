module Deaccessioned

  def self.included(base)
    base.extend(ClassMethods)
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

      objs.zip(jsons).each do |obj, json|
        json['deaccessioned'] = obj.deaccessioned?
      end

      jsons
    end
  end

end
