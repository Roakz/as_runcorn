require 'db/migrations/utils'

Sequel.migration do
  up do

    # resetting values for runcorn_format and runcorn_physical_representation_contained_within enums
    # where old values are deleted, pointing refs to the first of the old ones that is kept
    # completely restting the positions to match the order in these arrays.

    new_contained = [
                     'Digital media - External hard drive',
                     'Digital media - Flashdrive/USB/Thumbdrive',
                     'Digital media - Floppy disk - 3 1/2"',
                     'Digital media - Floppy disk - 5 1/4"',
                     'Digital media - Floppy disk - 8"',
                     'Digital media - Internal hard drive',
                     'Digital media - LTO computer tape',
                     'Digital media - Network Attached Storage (NAS)',
                     'Digital media - Optical  - CD',
                     'Digital media - Optical  - DVD',
                     'Digital Media - Other',
                     'Digital media - PC',
                     'Digital media - Server',
                     'Album',
                     'Box',
                     'Box - Card Box',
                     'Box - Microfiche Box',
                     'Box - Microfilm Box',
                     'Box - Phase Box',
                     'Box - Solander Box',
                     'Box - Type 1',
                     'Box - Type 1 (Archival)',
                     'Box - Type 10',
                     'Box - Type 10 (Archival)',
                     'Box - Type 11',
                     'Box - Type 11 (Archival)',
                     'Box - Type 2',
                     'Box - Type 2 (Archival)',
                     'Box - Type 3',
                     'Box - Type 3 (Archival)',
                     'Box - Type 5',
                     'Box - Type 5 (Archival)',
                     'Box - Type 6',
                     'Box - Type 6 (Archival)',
                     'Bundle',
                     'Canister',
                     'Canister - Film - Aerial',
                     'Canister - Film - non-vented',
                     'Canister - Film - vented',
                     'Carousel - Slide Carousel',
                     'Core',
                     'Drawer - Card Drawer',
                     'Encapsulate ',
                     'Folder',
                     'Folder - Map',
                     'Hanger',
                     'No Container',
                     'Other',
                     'Wrapping'
                    ]


    new_formats = [
                   'Architectural or technical drawing',
                   'Architectural or technical drawing - Blueprint - negative',
                   'Architectural or technical drawing - Blueprint - positive',
                   'Architectural or technical drawing - Composite',
                   'Architectural or technical drawing - Film',
                   'Architectural or technical drawing - Linen',
                   'Architectural or technical drawing - Paper',
                   'Artwork',
                   'Artwork - Banner',
                   'Artwork - Painting - framed',
                   'Artwork - Painting - unframed',
                   'Artwork - Poster - framed',
                   'Artwork - Poster - unframed',
                   'Artwork - Print - framed',
                   'Artwork - Print - unframed',
                   'Artwork - Sketch - framed',
                   'Artwork - Sketch - unframed',
                   'Cards',
                   'Cards - Punchcard',
                   'Chart (produced by machine) ',
                   'Chart (produced by machine) - Machine-generated (eg seismic, gyro)',
                   'Chart (produced by machine) - Stenotype Tape/Paper',
                   'Digital',
                   'File/document',
                   'File/document - Paper',
                   'File/document - Parchment',
                   'Film (roll)',
                   'Film (roll) - Aerial film roll - acetate',
                   'Film (roll) - Aerial film roll - polyester',
                   'Film (roll) - Motion picture - 16mm - acetate',
                   'Film (roll) - Motion picture - 16mm - polyester',
                   'Film (roll) - Motion picture - 35mm - acetate',
                   'Film (roll) - Motion picture - 35mm - polyester',
                   'Film (roll) - Motion picture - 8mm - acetate',
                   'Film (roll) - Motion picture - 8mm - polyester',
                   'Film (roll) - Motion picture - Super 8 - acetate',
                   'Film (roll) - Motion picture - Super 8 - poylester',
                   'Film (video)',
                   'Film (video) - 1" tape',
                   'Film (video) - 2" tape',
                   'Film (video) - Betacam',
                   'Film (video) - Betamax',
                   'Film (video) - Super VHS',
                   'Film (video) - U-Matic 3/4"',
                   'Film (video) - U-Matic small',
                   'Film (video) - VHS',
                   'Film (video) - Video casette other (handicam)',
                   'Map/plan',
                   'Map/plan - Blueprint - negative',
                   'Map/plan - Blueprint - positive',
                   'Map/plan - Composite',
                   'Map/plan - Film',
                   'Map/plan - Linen',
                   'Map/plan - Paper',
                   'Microform',
                   'Microform - Aperture card',
                   'Microform - Microfiche',
                   'Microform - Microfilm',
                   'Microform - Microfilm - 16mm - Duplicate',
                   'Microform - Microfilm - 16mm - Master',
                   'Microform - Microfilm - 16mm - Security',
                   'Microform - Microfilm - 35mm - Duplicate',
                   'Microform - Microfilm - 35mm - Master',
                   'Microform - Microfilm - 35mm - Security ',
                   'Microform - Microfilm - Duplicate',
                   'Microform - Microfilm - Master',
                   'Microform - Microfilm - Security',
                   'Object',
                   'Object - Architectural model/marquette',
                   'Object - Currency',
                   'Object - Honour Board',
                   'Object - Medals',
                   'Object - Printing Blocks',
                   'Object - Specimens',
                   'Other',
                   'Photographic',
                   'Photographic  - Glass Plate Negative',
                   'Photographic  - Glass Plate Negative - full plate',
                   'Photographic  - Glass Plate Negative - half plate',
                   'Photographic  - Glass Plate Negative - lantern slide',
                   'Photographic  - Glass Plate Negative - mammoth',
                   'Photographic  - Glass Plate Negative - quarter plate',
                   'Photographic  - Negative ',
                   'Photographic  - Negative - 120 - B&W - acetate',
                   'Photographic  - Negative - 120 - B&W - polyester',
                   'Photographic  - Negative - 120 - B&W - undetermined',
                   'Photographic  - Negative - 120 - Colour - acetate',
                   'Photographic  - Negative - 120 - Colour - polyester',
                   'Photographic  - Negative - 120 - Colour - undetermined',
                   'Photographic  - Negative - 35mm - B&W - acetate',
                   'Photographic  - Negative - 35mm - B&W - polyester',
                   'Photographic  - Negative - 35mm - B&W - undetermined',
                   'Photographic  - Negative - 35mm - Colour - acetate',
                   'Photographic  - Negative - 35mm - Colour - polyester',
                   'Photographic  - Negative - 35mm - Colour - undetermined',
                   'Photographic  - Negative - 4 x 5 - B&W - acetate',
                   'Photographic  - Negative - 4 x 5 - B&W - polyester',
                   'Photographic  - Negative - 4 x 5 - B&W - undetermined',
                   'Photographic  - Negative - 8 x 10 - B&W - acetate',
                   'Photographic  - Negative - 8 x 10 - B&W - polyester',
                   'Photographic  - Negative - 8 x 10 - B&W - undetermined',
                   'Photographic  - Print',
                   'Photographic  - Print - B&W',
                   'Photographic  - Print - Colour',
                   'Photographic  - Print - framed',
                   'Photographic  - Slide',
                   'Photographic  - Slide - 120 - B&W - acetate',
                   'Photographic  - Slide - 120 - B&W - polyester',
                   'Photographic  - Slide - 120 - B&W - undetermined',
                   'Photographic  - Slide - 120 - Colour - acetate',
                   'Photographic  - Slide - 120 - Colour - polyester',
                   'Photographic  - Slide - 120 - Colour - undetermined',
                   'Photographic  - Slide - 35mm - B&W - acetate',
                   'Photographic  - Slide - 35mm - B&W - polyester',
                   'Photographic  - Slide - 35mm - B&W - undetermined',
                   'Photographic  - Slide - 35mm - Colour - acetate',
                   'Photographic  - Slide - 35mm - Colour - polyester',
                   'Photographic  - Slide - 35mm - Colour - undetermined',
                   'Photographic  - Transparency',
                   'Photographic  - Transparency 120 - colour - acetate',
                   'Photographic  - Transparency 120 - colour - polyester',
                   'Photographic  - Transparency 120 - colour - undetermined',
                   'Photographic  - Transparency 35mm - colour - acetate',
                   'Photographic  - Transparency 35mm - colour - polyester',
                   'Photographic  - Transparency 35mm - colour - undetermined',
                   'Photographic  - Transparency 4 x 5 - colour',
                   'Photographic  - Print - Aerial',
                   'Photographic  - Print - Aerial - B&W',
                   'Photographic  - Print - Aerial - colour',
                   'Tape - sound recording',
                   'Tape - sound recording  - 8 Track audio',
                   'Tape - sound recording  - Audio 1" reel',
                   'Tape - sound recording  - Audio 1/4" reel',
                   'Tape - sound recording  - Audio 2" reel',
                   'Tape - sound recording  - Compact casette',
                   'Tape - sound recording  - Micro cassette',
                   'Tape - sound recording  - Mini cassette',
                   'Volume/register',
                   'Volume/register - Album',
                   'Volume/register - Copy Press (iron gall ink)',
                   'Volume/register - Copy Press (letterpress) ',
                   'Volume/register - Notebook',
                   'Volume/register - Parchment',
                   'Volume/register - Perfect bound',
                   'Volume/register - Post bound',
                   'Volume/register - Register - leather bound',
                   'Volume/register - Register - non leather bound',
                   'Volume/register - Ring bound',
                   'Volume/register - Spiral bound',
                  ]


    # contained_within

    new_contained = new_contained.map(&:strip).map{|cnt| cnt.gsub(/\s\s+/, ' ')}
    containeds = new_contained.clone
    contained_id = self[:enumeration].filter(:name => 'runcorn_physical_representation_contained_within').get(:id)
    current_containeds = self[:enumeration_value].filter(:enumeration_id => contained_id).select(:id, :value).all

    current_to_stay = []
    current_to_delete = []
    current_to_change = []

    pos = 10000

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
      self[:physical_representation].filter(:contained_within_id => cnt[:id]).update(:contained_within_id => current_to_stay.first[:id])
      self[:digital_representation].filter(:contained_within_id => cnt[:id]).update(:contained_within_id => current_to_stay.first[:id])
      self[:enumeration_value].filter(:id => cnt[:id]).delete
    end

    containeds.each do |cnt|
      self[:enumeration_value].insert(:enumeration_id => contained_id,
                                      :value => cnt,
                                      :readonly => 0,
                                      :position => pos,
                                      :suppressed => 0)
      pos += 1
    end

    new_contained.each_with_index do |cnt, ix|
      self[:enumeration_value].filter(:enumeration_id => contained_id, :value => cnt).update(:position => ix)
    end


    # format

    new_formats = new_formats.map(&:strip).map{|fmt| fmt.gsub(/\s\s+/, ' ')}
    formats = new_formats.clone
    format_id = self[:enumeration].filter(:name => 'runcorn_format').get(:id)
    current_formats = self[:enumeration_value].filter(:enumeration_id => format_id).select(:id, :value).all

    current_to_stay = []
    current_to_delete = []
    current_to_change = []

    pos = 10000

    current_formats.each do |fmt|
      if formats.delete(fmt[:value])
        # hooray a hit
        current_to_stay.push(fmt)
        self[:enumeration_value].filter(:id => fmt[:id]).update(:position => pos)
        pos += 1
      else
        val = fmt[:value]

        val.gsub!(/\s\s+/, ' ')

        if formats.delete(val)
          current_to_change.push(fmt[:value])
          self[:enumeration_value].filter(:id => fmt[:id]).update(:value => val, :position => pos)
          pos += 1
        else
          current_to_delete.push(fmt)
        end
      end
    end

    current_to_delete.each do |fmt|
      self[:physical_representation].filter(:format_id => fmt[:id]).update(:format_id => current_to_stay.first[:id])
      self[:enumeration_value].filter(:id => fmt[:id]).delete
    end

    formats.each do |fmt|
      self[:enumeration_value].insert(:enumeration_id => format_id,
                                      :value => fmt,
                                      :readonly => 0,
                                      :position => pos,
                                      :suppressed => 0)
      pos += 1
    end

    new_formats.each_with_index do |fmt, ix|
      self[:enumeration_value].filter(:enumeration_id => format_id, :value => fmt).update(:position => ix)
    end
  end

end

