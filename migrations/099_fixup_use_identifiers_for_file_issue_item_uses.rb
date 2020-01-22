require 'db/migrations/utils'

Sequel.migration do
  up do

    now = Time.now

    self[:item_use].filter(:item_use_type => 'file_issue').each do |iu|
      parsed = iu[:use_identifier].scan(/([^\d]+)?(\d+)/)[0]

      unless parsed[0].end_with?('P')
        new_use_id = [parsed[0], 'P', parsed[1]].join
        self[:item_use].filter(:id => iu[:id]).update(:use_identifier => new_use_id, :system_mtime => now)
      end
    end
  end
end
