class ConservationTreatment < Sequel::Model(:conservation_treatment)
  include ASModel
  corresponds_to JSONModel(:conservation_treatment)

  set_model_scope :global

  STATUS_AWAITING_TREATMENT = 'awaiting_treatment'
  STATUS_IN_PROGRESS = 'in_progress'
  STATUS_COMPLETED = 'completed'

  define_relationship(:name => :conservation_treatment_user,
                      :json_property => 'user',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

  define_relationship(:name => :conservation_treatment_assessment,
                      :json_property => 'assessment',
                      :contains_references_to_types => proc {[Assessment]},
                      :is_array => false)

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    applied_treatments_map = build_applied_treatments_map(objs)

    jsons.zip(objs).each do |json, obj|
      json['treatments'] = applied_treatments_map.fetch(obj.id, [])
    end

    jsons
  end

  def self.create_from_json(json, opts = {})
    extras = {
      :status => calculate_status(json),
    }

    if !json.treatment_batch_id
      extras[:treatment_batch_id] = Sequence.get("QSA_ASSESSMENT_TREATMENT_BATCH_ID").to_s
    end

    if json.persistent_create_time
      extras[:persistent_create_time] = json.persistent_create_time
    else
      extras[:persistent_create_time] = Time.now
    end

    obj = super(json, opts.merge(extras))
    self.apply_treatments(obj, json)
    obj
  end

  def self.handle_delete(ids_to_delete)
    DB.open do |db|
      db[:conservation_treatment_applied_treatment].filter(:conservation_treatment_id => ids_to_delete).delete
    end

    super
  end

  def self.calculate_status(json)
    if json['end_date']
      STATUS_COMPLETED
    elsif json['start_date']
      STATUS_IN_PROGRESS
    else
      STATUS_AWAITING_TREATMENT
    end
  end

  def self.apply_treatments(obj, json)
    DB.open do |db|
      db[:conservation_treatment_applied_treatment].filter(:conservation_treatment_id => obj.id).delete

      valid_attribute_ids = db[:assessment_attribute_definition]
                              .filter(:repo_id => [Repository.global_repo_id, active_repository])
                              .filter(:type => 'format')
                              .select(:id)
                              .map {|row| row[:id]}

      Array(json['treatments']).each do |treatment|
        next unless valid_attribute_ids.include?(treatment.fetch('definition_id'))

        db[:conservation_treatment_applied_treatment].insert(:conservation_treatment_id => obj.id,
                                                             :assessment_attribute_definition_id => treatment.fetch('definition_id'),
                                                             :created_by => RequestContext.get(:current_username),
                                                             :system_mtime => Time.now,
                                                             :last_modified_by => RequestContext.get(:current_username),
                                                             :user_mtime => Time.now)
      end

    end
  end

  def self.build_applied_treatments_map(objs)
    result = {}

    DB.open do |db|
      db[:conservation_treatment_applied_treatment]
        .join(:assessment_attribute_definition, Sequel.qualify(:assessment_attribute_definition, :id) => Sequel.qualify(:conservation_treatment_applied_treatment, :assessment_attribute_definition_id))
        .filter(:conservation_treatment_id => objs.map(&:id))
        .select(Sequel.qualify(:conservation_treatment_applied_treatment, :conservation_treatment_id),
                Sequel.qualify(:assessment_attribute_definition, :id),
                Sequel.qualify(:assessment_attribute_definition, :label))
        .map do |row|
        result[row[:conservation_treatment_id]] ||= []
        result[row[:conservation_treatment_id]] << {
          'definition_id' => row[:id],
          'label' => row[:label],
          'type' => 'format',
          'value' => 'true',
        }
      end
    end

    result
  end
end
