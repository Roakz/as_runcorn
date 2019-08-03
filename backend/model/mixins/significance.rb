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
    PhysicalRepresentation.filter(:archival_object_id => self.id)
                          .filter(Sequel.~(:significance_id => sig_id))
                          .filter(:significance_is_sticky => 0)
                          .update(:significance_id => sig_id,
                                  :system_mtime => Time.now)

    changing_children = self.children.filter(Sequel.~(:significance_id => sig_id)).filter(:significance_is_sticky => 0)

    changing_ids = changing_children.select(:id).all.map{|r| r[:id]}

    unless changing_ids.empty?
      changing_children.update(:significance_id => sig_id,
                               :lock_version => Sequel.expr(1) + :lock_version,
                               :system_mtime => Time.now)

      self.class.filter(:id => changing_ids).each{|cc| cc.apply_significance!(sig_id)}
    end
  end


  module ClassMethods
  end
end
