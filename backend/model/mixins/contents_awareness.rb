module ContentsAwareness

  def self.included(base)
    base.extend(ClassMethods)
  end


  def delete
    if (self.class.contents_count(self) > 0)
      raise ReferenceError.new('This container has contents references and cannot be removed')
    end

    super
  end


  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        json['contents_count'] = contents_count(obj)
        json['absent_contents'] = absent_contents(obj).map do |ac|
          {
            'ref' => JSONModel(:physical_representation).uri_for(ac[:id], :repo_id => obj.repo_id),
            'current_location' => ac[:loc],
            'title' => ac[:title]
          }

        end
      end

      jsons
    end


    def contents_count(obj)
      contents_ds(obj).count
    end


    def absent_contents(obj)
      contents_ds(obj)
        .left_join(Sequel.as(:enumeration_value, :loc), :id => :physical_representation__current_location_id)
        .exclude(:loc__value => 'HOME')
        .select(:physical_representation_id, :loc__value, :physical_representation__title)
        .all.map{|row| {:id => row[:physical_representation_id], :loc => row[:value], :title => row[:title]}}
    end


    def contents_ds(obj)
      db[:representation_container_rlshp]
        .join(:physical_representation, :physical_representation__id => :representation_container_rlshp__physical_representation_id)
        .filter(:top_container_id => obj.id)
    end
  end
end
