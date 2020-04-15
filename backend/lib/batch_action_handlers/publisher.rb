class Publisher < BatchActionHandler

  register(:publisher,
           'Publish or unpublish items and representations. Objects already in the target state will not be updated',
           [:archival_object, :physical_representation, :digital_representation],
           :manage_publication)


  def self.default_params
    {
      'publish' => true
    }
  end


  def self.validate_params(params)
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    counts = {}
    already = {}
    unpublishable = {}
    unapproved = []

    publish = params['publish'] ? 1 : 0
    now = Time.now

    DB.open do |db|
      uris.map {|uri| {:uri => uri, :parsed => JSONModel.parse_reference(uri)}}
          .group_by {|parsed| parsed[:parsed].fetch(:type)}
          .each do |type, type_refs|

        model = ASModel.all_models.select{|m| m.table_name == type.intern}.first

        objs = model.filter(:id => type_refs.map {|ref| ref[:parsed].fetch(:id)})
          .filter(Sequel.~(:publish => publish)).all

        raps = RAPsApplied::RAPApplications.new(objs)

        all_count = objs.length

        if type_refs.length > all_count
          already[type] = type_refs.length - all_count
        end

        if publish == 1
          # if we're trying to publish, only publish the publishable!
          objs = objs.select do |obj|
            rap_applied = raps.rap_json_for_rap_applied(obj.id)
            rap_expiration = raps.rap_expiration_for_rap_applied(obj.id)


            !rap_applied['is_repository_default'] && rap_applied['access_category'] != RAP::ACCESS_CATEGORY_NA &&
              (rap_applied['open_access_metadata'] || rap_expiration['expired'])
          end

          if all_count > objs.length
            unpublishable[type] = all_count - objs.length
          end

          if (unapproved_objs = objs.select{|obj| obj[:archivist_approved] != 1}).length > 0
            unapproved.concat(unapproved_objs.map{|obj| obj.qsa_id_prefixed})
          end
        end

        ids = objs.map {|obj| obj[:id]}

        counts[type] = db[type.intern].filter(:id => ids)
                                      .update(:publish => publish,
                                              :lock_version => Sequel.expr(1) + :lock_version,
                                              :system_mtime => now,
                                              :user_mtime => now,
                                              :last_modified_by => user)

        # for archival_objects, touch any attached representations to ensure they get reindexed
        if type.intern == :archival_object
          [:physical_representation, :digital_representation].each do |rep_model|
            db[rep_model].filter(:archival_object_id => ids)
                         .update(:system_mtime => now)
          end
        end

        # ... and turns out public needs the inverse
        if [:physical_representation, :digital_representation].include?(type.intern)
          db[:archival_object]
            .inner_join(type.intern, Sequel.qualify(type.intern, :archival_object_id) => Sequel.qualify(:archival_object, :id))
            .filter(Sequel.qualify(type.intern, :id) => ids)
            .update(Sequel.qualify(:archival_object, :system_mtime) => now)
        end
      end
    end

    state = "#{publish == 1 ? '' : 'un'}published"

    out = "Number of objects #{state}:\n"
    out += counts.map{|model, count| "    #{I18n.t(model + '._singular')}: #{count}" }.join("\n")

    unless unpublishable.empty?
      out += "\n\nNumber of objects not published due to RAP restrictions:\n"
      out += unpublishable.map{|model, count| "    #{I18n.t(model + '._singular')}: #{count}" }.join("\n")
    end

    unless already.empty?
      out += "\n\nNumber of objects not updated because they are already #{state}:\n"
      out += already.map{|model, count| "    #{I18n.t(model + '._singular')}: #{count}" }.join("\n")
    end

    unless unapproved.empty?
      out += "\n\n** WARNING **\n"
      out += "Objects published but not yet approved by a senior archivist:\n    "
      out += unapproved.join("\n    ")
    end

    out
  end
end
