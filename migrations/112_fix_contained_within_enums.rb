require 'db/migrations/utils'

Sequel.migration do
  up do

    # migration 107 erroneously conflated contained_within enum values
    # for physical and digital reps. They have separate sets of values.
    # This migration fixes that by pulling the digital ones out and
    # using those to rebuild the digital enum. Fun times!

    dig_contained = [
                     'Digital media - External hard drive',
                     'Digital media - Flashdrive/USB/Thumbdrive',
                     'Digital media - Floppy disk - 3 1/2"',
                     'Digital media - Floppy disk - 5 1/4"',
                     'Digital media - Floppy disk - 8"',
                     'Digital media - Internal hard drive',
                     'Digital media - LTO computer tape',
                     'Digital media - Network Attached Storage (NAS)',
                     'Digital media - Optical - CD',
                     'Digital media - Optical - DVD',
                     'Digital Media - Other',
                     'Digital media - PC',
                     'Digital media - Server',
                    ]

    # first remove dig values from runcorn_physical_representation_contained_within
    phys_contained_id = self[:enumeration].filter(:name => 'runcorn_physical_representation_contained_within').get(:id)
    dig_contained_id = self[:enumeration].filter(:name => 'runcorn_digital_representation_contained_within').get(:id)

    bad_phys_ids = self[:enumeration_value].filter(:enumeration_id => phys_contained_id).filter(:value => dig_contained).map{|ev| ev[:id]}
    move_em_here_id = self[:enumeration_value].filter(:enumeration_id => phys_contained_id).exclude(:value => dig_contained).get(:id)
    self[:physical_representation].filter(:contained_within_id => bad_phys_ids).update(:contained_within_id => move_em_here_id)

    # then delete the dig values from the phys enum
    self[:enumeration_value].filter(:enumeration_id => phys_contained_id).filter(:value => dig_contained).delete


    # then fix up the dig enum
    containeds = dig_contained.clone

    current_containeds = self[:enumeration_value].filter(:enumeration_id => dig_contained_id).select(:id, :value).all

    current_to_stay = []
    current_to_delete = []
    current_to_change = []

    pos = 100000

    current_containeds.each do |cnt|
      if containeds.delete(cnt[:value])
        current_to_stay.push(cnt)
        self[:enumeration_value].filter(:id => cnt[:id]).update(:position => pos)
        pos += 1
      else
        val = cnt[:value]

        val.gsub!(/\s\s+/, ' ')

        if containeds.delete(val)
          current_to_change.push(cnt[:value])
          self[:enumeration_value].filter(:id => cnt[:id]).update(:value => val, :position => pos)
          pos += 1
        else
          current_to_delete.push(cnt)
        end
      end
    end

    current_to_delete.each do |cnt|
      self[:digital_representation].filter(:contained_within_id => cnt[:id]).update(:contained_within_id => current_to_stay.first[:id])
      self[:enumeration_value].filter(:id => cnt[:id]).delete
    end

    containeds.each do |cnt|
      self[:enumeration_value].insert(:enumeration_id => dig_contained_id,
                                      :value => cnt,
                                      :readonly => 0,
                                      :position => pos,
                                      :suppressed => 0)
      pos += 1
    end

    dig_contained.each_with_index do |cnt, ix|
      self[:enumeration_value].filter(:enumeration_id => dig_contained_id, :value => cnt).update(:position => ix)
    end
  end

end

