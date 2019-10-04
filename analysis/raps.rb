require 'csv'

CHOICES = [
  [
    "RAP applied?",
    'TRUE',
    'FALSE',
  ],

  [
    "Access Category",
    'N/A',
    '1-8',
    '9-13',
  ],

  [
    "Open access metadata",
    'TRUE',
    'FALSE',
  ],

  [
    "Years",
    'null',
    '0',
    '1-100',
  ],

  [
    "RAP Expired?",
    'TRUE',
    'FALSE',
  ],

  [
    "Record has end date?",
    'TRUE',
    'FALSE',
  ],

]




# {"Access Category" => "N/A", ...}

def permutations_of_choices(choices)
  if choices.empty?
    [{}]
  else
    (first, rest) = choices[0], choices.drop(1)

    sub_choices = permutations_of_choices(rest)

    sub_choices.map {|choice|
      label = first[0]
      values = first.drop(1)

      values.map {|value|
        choice.merge(label => value)
      }
    }.flatten(1)
  end
end


permutations = permutations_of_choices(CHOICES)

permutations.each do |perm|
  if perm.fetch("RAP applied?") == 'FALSE' && perm.fetch("RAP Expired?") == 'TRUE'
    perm['ruling'] = "{Invalid state}: if a RAP isn't applied there's nothing to expire"
  elsif perm.fetch("RAP applied?") == 'FALSE' && (perm.fetch("Years") != 'null' || perm.fetch("Access Category") != 'N/A' || perm.fetch("Open access metadata") != 'FALSE')
    perm['ruling'] = "{Invalid state}: System RAP is always null years, N/A category and no Open Acces Metadata"
  elsif perm.fetch("Record has end date?") == 'FALSE' && perm.fetch("RAP Expired?") == 'TRUE'
    perm['ruling'] = "{Invalid state}: if a record has no end date its RAP never expires"
  elsif perm.fetch("Years") == 'null' && perm.fetch("RAP Expired?") == 'TRUE'
    perm['ruling'] = "{Invalid state}: if rap.years is null, it never expires"
  elsif perm.fetch('Access Category') == '9-13' && perm.fetch('Years') != 'null'
    perm['ruling'] = "{Invalid state}: Access Category implies always closed, so years doesn't make sense"
  elsif perm.fetch('Access Category') == 'N/A' && perm.fetch('Years') != 'null'
    perm['ruling'] = '{Invalid state}: Access Category N/A implies system default RAP (permanently closed)'
  elsif perm.fetch('Access Category') == 'N/A' && perm.fetch('Years') == 'null' && perm.fetch('Open access metadata') == 'TRUE'
    perm['ruling'] = '{Invalid state}: N/A implies permanently closed'


  elsif perm.fetch("RAP applied?") == 'FALSE'
    perm['ruling'] = "System RAP is applied and never expires"
  elsif perm.fetch('Record has end date?') == 'FALSE'
    if perm.fetch('Open access metadata') == 'TRUE'
      perm['ruling'] = 'Open metadata; Closed record - record has no end date'
    else
      perm['ruling'] = 'Closed metadata; Closed record - record has no end date'
    end
  elsif perm.fetch('Access Category') == '9-13' && perm.fetch('Years') == 'null'
    if perm.fetch('Open access metadata') == 'TRUE'
      perm['ruling'] = 'Open metadata; Closed record (permanently closed)'
    else
      perm['ruling'] = 'Closed metadata; Closed record (permanently closed)'
    end
  elsif perm.fetch('Access Category') == '1-8' && perm.fetch('Years') == '0'
    if perm.fetch('RAP Expired?') == 'FALSE'
      if perm.fetch('Open access metadata') == 'TRUE'
        perm['ruling'] = 'Open metadata; Closed record (record end date is in the future)'
      else
        perm['ruling'] = 'Closed metadata; Closed record (record end date is in the future)'
      end
    else
      perm['ruling'] = 'Open metadata; Open record (RAP expired)'
    end
  elsif perm.fetch('Access Category') == '1-8' && perm.fetch('Years') != 'null'
    if perm.fetch('RAP Expired?') == 'TRUE'
      perm['ruling'] = 'Open metadata; Open record (RAP expired)'
    else
      if perm.fetch('Open access metadata') == 'TRUE'
        perm['ruling'] = 'Open metadata; Closed record (RAP in effect)'
      else
        perm['ruling'] = 'Closed metadata; Closed record (RAP in effect)'
      end
    end
  elsif perm.fetch('Access Category') == '1-8' && perm.fetch('Years') == 'null'
    perm['ruling'] = "{Invalid state}: won't happen because years will default to 100"
  elsif perm.fetch('Access Category') == 'N/A' && perm.fetch('Years') == 'null'
    if perm.fetch('Open access metadata') == 'FALSE'
      # Other arm of this handled as invalid state above
      perm['ruling'] = 'Closed metadata; Closed record (show as system default RAP)'
    end
  end
end


# puts "Perms with rulings: " + permutations.select {|perm| perm['ruling']}.length.to_s
# puts "Perms without rulings: " + permutations.select {|perm| !perm['ruling']}.length.to_s
# 
# 
# 
# 
# permutations.select {|perm| !perm['ruling']}.each do |missed|
#   p missed
# end


keys = CHOICES.map(&:first) + ['ruling']

csv_s = CSV.generate do |csv|
  csv << keys

  permutations.each do |row|
    csv << keys.map {|k| row[k]}
  end
end

puts csv_s.to_s
