class Batch < Sequel::Model(:batch)
  include ASModel
  corresponds_to JSONModel(:batch)

  set_model_scope :repository

  define_relationship(:name => :batch_action_batch,
                      :json_property => 'actions',
                      :contains_references_to_types => proc {[BatchAction]})

  class UnsupportedModel < StandardError; end

  def self.models
    @models ||= BackendEnumSource.values_for('runcorn_batch_model').map{|m| m.intern}
  end


  def self.id_column_map
    @column_map ||= models.map{|m| [m, :"#{m}_id"]}.to_h
  end


  def self.id_columns
    id_column_map.values
  end


  def self.id_column_for(model)
    id_column_map[model] or raise UnsupportedModel.new(model)
  end


  def self.id_column_to_model(col)
    col.to_s.sub(/_id$/, '').intern
  end


  def self.column_for_row(row)
    row.select{|k,v| !v.nil?}.keys.first
  end


  def add_objects(model, *ids)
    id_col = Batch.id_column_for(model)

    ids = ids.uniq

    DB.open do |db|
      # Clear any existing entries so we don't end up with duplicates
      db[:batch_objects].filter(id_col => ids, :batch_id => self.id).delete
      db[:batch_objects].multi_insert(ids.map {|id| {id_col => id, :batch_id => self.id}})
    end
  end


  def remove_objects(model, *ids)
    id_col = Batch.id_column_for(model)

    ids = ids.uniq

    DB.open do |db|
      db[:batch_objects].filter(id_col => ids, :batch_id => self.id).delete
    end
  end


  def objects_ds
    DB.open do |db|
      db[:batch_objects]
        .filter(:batch_id => self.id)
        .select(*Batch.id_columns)
    end
  end


  def object_refs
    objects_ds.map{|row| uri_for_batch_objects_row(row)}
  end


  def object_counts
    objects_ds.group_and_count{Batch.id_columns.map{|col| Sequel.~(col => nil).as(col)}}.map{|row|
      [Batch.id_column_to_model(row.select{|k,v| v == true}.keys.first), row[:count]]
    }.to_h
  end


  def included_models
    object_counts.keys
  end


  def uri_for_batch_objects_row(row)
    col = Batch.column_for_row(row)
    id = row[col]

    JSONModel(Batch.id_column_to_model(col)).uri_for(id, :repo_id => RequestContext.get(:repo_id))
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
    end

    jsons
  end

end
