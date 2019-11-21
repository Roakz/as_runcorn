# WARNING: as written this only supports being mixed in by archival objects

module Significance

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    sig_id = BackendEnumSource.id_for_value('runcorn_significance', json['significance'])

    if sig_id != self.significance_id
      obj = super
      self.apply_significance!(sig_id)
      return obj
    end

    super
  end


  def apply_significance!(sig_id)
    counts = {}

    counts['physical_representation'] = 
      PhysicalRepresentation.filter(:archival_object_id => self.id)
      .filter(Sequel.~(:significance_id => sig_id))
      .filter(:significance_is_sticky => 0)
      .update(:significance_id => sig_id,
              :system_mtime => Time.now)

    changing_children = self.children.filter(Sequel.~(:significance_id => sig_id)).filter(:significance_is_sticky => 0)

    changing_ids = changing_children.select(:id).all.map{|r| r[:id]}

    unless changing_ids.empty?
      counts['archival_object'] =
        changing_children.update(:significance_id => sig_id,
                                 :lock_version => Sequel.expr(1) + :lock_version,
                                 :system_mtime => Time.now)

      self.class.filter(:id => changing_ids).each do |cc|
        cc.apply_significance!(sig_id).each{|m,c| counts[m] += c}
      end
    end

    counts
  end


  module ClassMethods
    def create_from_json(json, extra_values = {})
      obj = super
      unless ASUtils.migration_mode?
        obj.apply_significance!(obj.significance_id)
      end
      obj
    end
  end
end
