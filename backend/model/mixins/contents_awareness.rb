module ContentsAwareness

  ABSENT_CONTENTS_DISPLAY_LIMIT = 10

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
        json['absent_contents_count'] = absent_contents_count(obj)
        json['absent_contents'] = absent_contents(obj)
      end

      jsons
    end


    def contents_count(obj)
      db[:representation_container_rlshp].filter(:top_container_id => obj.id).count
    end


    def absent_contents_ds(obj)
      db[:representation_container_rlshp]
        .join(:physical_representation, :physical_representation__id => :representation_container_rlshp__physical_representation_id)
        .filter(:representation_container_rlshp__top_container_id => obj.id)
        .filter(Sequel.~(:physical_representation__current_location_id => BackendEnumSource.id_for_value('runcorn_location', 'HOME')))
    end


    def absent_contents_count(obj)
      absent_contents_ds(obj).count
    end


    def absent_contents(obj)
      absent_contents_ds(obj)
        .limit(ABSENT_CONTENTS_DISPLAY_LIMIT)
        .select(Sequel.qualify(:representation_container_rlshp, :physical_representation_id),
                Sequel.qualify(:physical_representation, :current_location_id),
                Sequel.qualify(:physical_representation, :title))
        .map do |row|
        {
          :ref => JSONModel(:physical_representation).uri_for(row[:physical_representation_id], :repo_id => obj.repo_id),
          :current_location => BackendEnumSource.value_for_id('runcorn_location', row[:current_location_id]),
          :title => row[:title]
        }
      end
    end
  end
end
