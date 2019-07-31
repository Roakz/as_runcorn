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

  def self.create_from_json(json, opts = {})
    super(json, opts.merge(:status => calculate_status(json)))
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    self[:status] = self.class.calculate_status(json)
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
end
