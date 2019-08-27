module RepresentationControl

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def build_controlling_record_map(objs)
      controlling_records_by_representation_id = {}
      Representations.supported_models.each do |model|
        next unless model.ancestors.include?(ControlledRecord)

        # e.g. archival_object_id
        backlink_col = "#{model.table_name}_id".intern

        controlling_records = model
                                .filter(:id => self.filter(:id => objs.map(&:id)).select(backlink_col))
                                .all
                                .group_by(&:id)

        self.filter(:id => objs.map(&:id)).select(:id, Sequel.as(backlink_col, :controlling_id)).each do |row|
          controlling_records_by_representation_id[row[:id]] = controlling_records.fetch(row[:controlling_id]).first
        end
      end

      controlling_records_by_representation_id
    end

    def build_ancestor_published_map(objs)
      ao_ids = objs.map(&:archival_object_id)

      publish_map = {}
      parent_map = {}

      ArchivalObject
        .join(:resource, Sequel.qualify(:resource, :id) => Sequel.qualify(:archival_object, :root_record_id))
        .filter(Sequel.qualify(:archival_object, :id) => ao_ids)
        .select(Sequel.qualify(:archival_object, :id),
                Sequel.qualify(:archival_object, :parent_id),
                Sequel.as(Sequel.qualify(:archival_object, :publish), :linked_item_publish),
                Sequel.as(Sequel.qualify(:resource, :publish), :series_publish))
        .each do |row|
        publish_map[row[:id]] = row[:linked_item_publish] == 1 && row[:series_publish] == 1
        parent_map[row[:id]] = row[:parent_id]
      end

      if publish_map.values.any?{|val| val}
        # up the tree we go!
        ids_to_process = parent_map.values.compact.uniq
        while(!ids_to_process.empty?) do
          next_ids_to_process = []
          ArchivalObject
            .filter(:id => ids_to_process)
            .select(:id,
                    :parent_id,
                    :publish)
            .each do |row|
            parent_map[row[:id]] = row[:parent_id]

            # only override an AO publish value if it is currently true
            if !publish_map.has_key?(row[:id]) || publish_map[row[:id]] == true
              publish_map[row[:id]] = row[:publish] == 1
            end
            next_ids_to_process << row[:parent_id]
          end

          ids_to_process = next_ids_to_process.compact.uniq
        end
      end

      Hash[objs.map {|obj|
        node_id = obj.archival_object_id
        published = publish_map.fetch(node_id)

        while(node_id && published) do
          published = publish_map.fetch(node_id)
          node_id = parent_map[node_id]
        end

        [obj.id, published]
      }]
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      ancestor_published_map = build_ancestor_published_map(objs)

      objs.zip(jsons).each do |obj, json|
        json['has_unpublished_ancestor'] = !ancestor_published_map.fetch(obj.id, false)
      end

      jsons
    end
  end

end
