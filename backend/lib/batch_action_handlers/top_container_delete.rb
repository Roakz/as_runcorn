class TopContainerDelete < BatchActionHandler

  register(:top_container_delete,
           'Delete top containers.',
           [:top_container],
           :manage_container_record)


  def self.default_params
    {}
  end


  def self.validate_params(params)
    # no params
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    count = 0
    no_count = 0
    deletes = []
    errors = {}

    ids = {:top_container => []}

    DB.open do |db|
      uris.each do |uri|
        ref = JSONModel.parse_reference(uri)

        tc = TopContainer[ref[:id]]

        begin
          db[:batch_objects].filter(:top_container_id => tc.id).delete
          tc.delete()
          deletes.push(tc.qsa_id_prefixed + (' ' * ([10 - tc.qsa_id_prefixed.length, 1].max)) + tc.long_display_string)
          count += 1
        rescue => e
          errors[e.to_s] ||= []
          errors[e.to_s].push(tc.qsa_id_prefixed + (' ' * ([10 - tc.qsa_id_prefixed.length, 1].max)) + tc.long_display_string)
          no_count += 1
        end

      end
    end

    out = "Deleted #{count} top container#{count == 1 ? '' : 's'}."

    if count > 0
      out += "\n\nDeleted top containers:\n    "
      out += deletes.join("\n    ")
    end

    if no_count > 0
      out += "\n\nCouldn't delete #{no_count} top container#{no_count == 1 ? '' : 's'}."
      out += "\n\nReason for delete failures:"
      errors.each do |error, tc|
        out += "\n    #{error}:\n        "
        
        out += tc.join("\n        ")
      end
    end

    out
  end
end
