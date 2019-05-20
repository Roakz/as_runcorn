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
  end

end
