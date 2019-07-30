require 'db/migrations/utils'

Sequel.migration do

  up do
    # reusing the 'format' type because it isn't required by qsa and it turns out
    # adding a new type requires hacking around inside the Assessment model
    format_ids = self[:assessment_attribute_definition].filter(:type => 'format').select(:id)
    self[:assessment_attribute].filter(:assessment_attribute_definition_id => format_ids).delete
    self[:assessment_attribute_definition].filter(:type => 'format').delete

   TYPES.each_with_index do |treatment, ix|
      self[:assessment_attribute_definition].insert(:repo_id => 1, :label => treatment, :type => 'format', :position => ix)
    end
  end

  down do
  end
end


TYPES = [
         'adhere',
         'adhesive removal',
         'air dry',
         'annoxic',
         'apply fasteners',
         'assemble fragments',
         'backing removal',
         'bag/isolate',
         'binding removed',
         'brush vacuum',
         'cleaning - dry',
         'cleaning - wet',
         'consolidation',
         'custom box',
         'custom housing',
         'custom support',
         'deacidify',
         'demetal',
         'digitisation',
         'encapsulate',
         'finishing',
         'flatten - iron',
         'flatten- press',
         'folder',
         'foreign material removed',
         'freezing',
         'fumigate',
         'guard removal',
         'heat lamination',
         'heat-set repair',
         'humidify/relax',
         'infill',
         'interleave',
         'line - heat',
         'line - pressure',
         'line - tension',
         'matt',
         'mould remediation',
         'pull down register',
         'rebind',
         're-core',
         'reformatting',
         'rehouse',
         'remove fasteners',
         'separation',
         'sew',
         'size',
         'solvent lamination',
         'stain reduction',
         'steam relaxation',
         'support board',
         'tape removal',
         'Test - ink solubility',
         'Test - Iron gall',
         'Test - pH',
         'Test - solubility other',
         'tradiitonal tear repair',
         'wash',
         'wrap',
         'Other',
         'comments',
         'adsorbant',
         'heat treatment',
         'vacuum freeze dry',
         'resplice',
         'Test - AD',
]
