class ItemApproval < BatchActionHandler

  register(:item_approval,
           'Set approval fields on Items and Representations.',
           [:archival_object, :physical_representation, :digital_representation])


  def self.default_params
    # flaming push ups just to pre-populate a linker :(
    current_user = User[:username => RequestContext.get(:current_username)]
    agent_type = current_user.agent_record_type.intern
    agent_model = ASModel.all_models.select{|m| m.table_name == agent_type}.first
    user_json = agent_model.to_jsonmodel(current_user.agent_record_id)

    {
      'approver_uri' => user_json['uri'],
      'approver_label' => user_json['title'],
      'date' => Date.today.iso8601,
      'approved' => true,
    }
  end


  def self.validate_params(params)
  end


  def self.process_form_params(params)
    approver = params['_resolved'] ? ASUtils.json_parse(params['_resolved']) : {}
    {
      'approver_uri' => approver['uri'] || params['approver_uri'],
      'approver_label' => approver['title'] || params['approver_label'],
      'date' => params['date'],
      'approved' => params['approved'],
    }
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    approver_id = params['approver_uri'] ? JSONModel.parse_reference(params['approver_uri'])[:id] : false

    username = RequestContext.get(:current_username)
    now = Time.now

    representation_approved_by_rlshp_row = {
      :resource_id => nil,
      :archival_object_id => nil,
      :physical_representation_id => nil,
      :digital_representation_id => nil,
      :agent_person_id => approver_id,
      :aspace_relationship_position => 0,
      :created_by => username,
      :last_modified_by => username,
      :system_mtime => now,
      :user_mtime => now,
    }

    counts = {}


    DB.open do |db|
      uris.map {|uri| {:uri => uri, :parsed => JSONModel.parse_reference(uri)}}
          .group_by {|parsed| parsed[:parsed].fetch(:type)}
          .each do |type, type_refs|

        ids = type_refs.map{|r| r[:parsed][:id]}

        counts[type] = ids.length

        db[type.intern].filter(:id => ids)
          .update(:approval_date => params['date'],
                  :archivist_approved => params['approved'] ? 1 : 0,
                  :lock_version => Sequel.expr(1) + :lock_version,
                  :system_mtime => now,
                  :user_mtime => now,
                  :last_modified_by => user)

        rlshp_id_col = "#{type}_id".intern
        db[:representation_approved_by_rlshp].filter(rlshp_id_col => ids).delete

        if approver_id
          ids.each do |id|
            db[:representation_approved_by_rlshp].insert(representation_approved_by_rlshp_row.merge({rlshp_id_col => id}))
          end
        end
      end
    end

    out = "Number of objects updated:\n    "
    out += counts.map{|model, count| "    #{I18n.t(model + '._singular')}: #{count}" }.join("\n")

    out
  end
end
