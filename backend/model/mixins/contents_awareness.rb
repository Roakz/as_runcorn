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

      location_enum_map = BackendEnumSource.values_for('runcorn_location').map{|value|
        [BackendEnumSource.id_for_value('runcorn_location', value), value]
      }.to_h
      home_id = BackendEnumSource.id_for_value('runcorn_location', 'HOME')

      objs.zip(jsons).each do |obj, json|
        json['contents_count'] = contents_count(obj)
        json['absent_contents'] = absent_contents(obj, location_enum_map, home_id).map do |ac|
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
      db[:representation_container_rlshp].filter(:top_container_id => obj.id).count
    end


    def absent_contents(obj, location_enum_map, home_id)
      db[:representation_container_rlshp]
        .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:representation_container_rlshp, :physical_representation_id))
        .filter(Sequel.qualify(:representation_container_rlshp, :top_container_id) => obj.id)
        .filter(Sequel.~(Sequel.qualify(:physical_representation, :current_location_id) => home_id))
        .select(Sequel.qualify(:representation_container_rlshp, :physical_representation_id),
                Sequel.qualify(:physical_representation, :current_location_id),
                Sequel.qualify(:physical_representation, :title))
        .map do |row|
          {
            :id => row[:physical_representation_id],
            :loc => location_enum_map.fetch(row[:current_location_id]),
            :title => row[:title]
          }
        end
    end

  end
end
