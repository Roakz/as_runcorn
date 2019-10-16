class SignificanceLevel < BatchActionHandler

  register(:significance_level,
           'Change significance level for all objects of a given level.',
           [:archival_object, :physical_representation],
           :manage_repository)


  def self.default_params
    {
      'match_level' => 'standard',
      'change_to_level' => 'standard',
      'make_sticky' => true
    }
  end


  def self.validate_params(params)
    match_level = params['match_level'] or raise InvalidParams.new('Must provide a level to match')
    change_to_level = params['change_to_level'] or raise InvalidParams.new('Must provide a level to change to')

    levels = BackendEnumSource.values_for('runcorn_significance')
    unless levels.include?(match_level)
      raise InvalidParams.new('Level to match must be one of: ' + levels.join(', '))
    end
    unless levels.include?(change_to_level)
      raise InvalidParams.new('Level to change to must be one of: ' + levels.join(', '))
    end
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    counts = {}

    match_level_id = BackendEnumSource.id_for_value('runcorn_significance', params['match_level'])
    change_to_level_id = BackendEnumSource.id_for_value('runcorn_significance', params['change_to_level'])
    sticky = params['make_sticky'] ? 1 : 0
    now = Time.now

    DB.open do |db|
      uris.map {|uri| {:uri => uri, :parsed => JSONModel.parse_reference(uri)}}
        .group_by {|parsed| parsed[:parsed].fetch(:type)}
        .each do |type, type_refs|

        ids = db[type.intern].filter(:id => type_refs.map {|ref| ref[:parsed].fetch(:id)})
                             .filter(:significance_id => match_level_id)
                             .map{|row| row[:id]}

        counts[type] =
          db[type.intern].filter(:id => ids)
          .update(:significance_id => change_to_level_id,
                  :significance_is_sticky => sticky,
                  :lock_version => Sequel.expr(1) + :lock_version,
                  :system_mtime => now,
                  :user_mtime => now,
                  :last_modified_by => user)

        model = ASModel.all_models.select{|m| m.table_name == type.intern}.first

        if model.ancestors.include?(Significance)
          ids.each do |id|
            model[id].apply_significance!(change_to_level_id).each do |m,c|
              if c > 0
                counts[m] ||= 0
                counts[m] += c
              end
            end
          end
        end
      end

    end

    out = "Objects with significance of:\n    "
    out += I18n.t('enumerations.runcorn_significance.' + params['match_level'])
    out += "\n\nhad their significance changed to:\n    "
    out += I18n.t('enumerations.runcorn_significance.' + params['change_to_level'])
    out += " (#{sticky == 1 ? 'not ' : ''}inheriting):\n"
    out += "\n\nNumber of objects affected (including inheriting children):\n"
    out += counts.map{|model, count| "    #{I18n.t(model + '._singular')}: #{count}"}.join("\n")
    out
  end
end
