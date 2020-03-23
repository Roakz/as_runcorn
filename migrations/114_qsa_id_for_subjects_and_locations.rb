require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:subject) do
      add_column(:qsa_id, Integer, :index => true, :null => true)
    end

    alter_table(:location) do
      add_column(:qsa_id, Integer, :index => true, :null => true)
    end

    self.transaction do
      self[:subject].update(:qsa_id => :id)

      if self[:subject].max(:qsa_id)
        self[:sequence].insert(:sequence_name => "QSA_ID_SUBJECT", :value => self[:subject].max(:qsa_id) + 1)
      end

      self[:location].update(:qsa_id => :id)

      if self[:location].max(:qsa_id)
        self[:sequence].insert(:sequence_name => "QSA_ID_LOCATION", :value => self[:location].max(:qsa_id) + 1)
      end
    end
  end

end
