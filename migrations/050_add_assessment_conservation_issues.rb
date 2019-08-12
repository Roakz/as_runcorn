require 'db/migrations/utils'

Sequel.migration do

  up do
    format_ids = self[:assessment_attribute_definition].filter(:type => 'rating').select(:id)
    self[:assessment_attribute].filter(:assessment_attribute_definition_id => format_ids).delete
    self[:assessment_attribute_note].filter(:assessment_attribute_definition_id => format_ids).delete
    self[:assessment_attribute_definition].filter(:type => 'rating').delete

   RATINGS.each_with_index do |rating, ix|
      self[:assessment_attribute_definition].insert(:repo_id => 1, :label => rating, :type => 'rating', :position => ix)
    end
  end

  down do
  end
end


RATINGS = [
           'abraded',
           'accretions',
           'acidic',
           'adhesive residue',
           'Volume Boards',
           'Sewing',
           'Spine Cover',
           'bleeding inks',
           'brittle',
           'cockling',
           'concealed/enclosed',
           'contaminated - mould active',
           'contaminated - mould dormant',
           'contaminated - other',
           'corrosion - iron gall',
           'corrosion - other',
           'corrosion - rust',
           'crosslinked',
           'curled',
           'delamination',
           'discolouration',
           'distorted/warped',
           'dust',
           'efflourescence/crystals',
           'fading',
           'flaking',
           'folded',
           'foxing',
           'heat damage',
           'holes',
           'incompatible materials',
           'ink haloing',
           'Staining',
           'laminated',
           'losses',
           'marks - highlighter etc',
           'off-gassing',
           'pages adhered',
           'parts missing',
           'pest damage',
           'plasticiser migration',
           'powdering',
           'previous repairs',
           'red rot',
           'rolled - memory',
           'rubber bands',
           'scratched',
           'smoke damage',
           'insect damage',
           'surface dirt',
           'tacky',
           'tape',
           'tears - edge',
           'tears - significant',
           'water damage',
           'wear and tear',
           'wet',
           'yellowed',
           'change in opacity',
           'chipped',
           'coating - intact',
           'coating - damaged',
           'cracked',
           'crizzled',
           'cut',
           'etched',
           'oxidation',
           'spue',
           'stretched',
           'channeling',
           'shedding',
           'shrinkage',
           'silvering out',
           'spoking',
           'Vinegar Syndrome',
          ]
