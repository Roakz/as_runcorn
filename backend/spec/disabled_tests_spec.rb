# don't run tests that are no longer valid because of the changes we've made
disabled_tests =
  [
   "Resources controller doesn't let you create a resource without a 4-part identifier",
   'Resource model reports an error if id_0 has no value',
   'Resource model prevents duplicate IDs',
   'Archival Object controller allows some non-alphanumeric characters in ref_ids',
   'Archival Object controller enforces uniqueness of ref_ids within a Resource',
   'ArchivalObject model enforces ref_id uniqueness only within a resource',
   'Resource Component Transfer Endpoint returns a 400 response code when asked to transfer an object to a resource containing a conflicting object',
   'Accession model enforces ID uniqueness',
   'Accession model enforces ID max length',
   'Digital object model prevents duplicate IDs',
   'Record Suppression prevents updates to suppressed accession records',
   'Agent model returns the existing agent if an name authority id is already in place',
   'Record transfers Full repository transfers reports conflicts between the records in two repositories being merged',
   'MARCXML converter',
   'MARC Export',
   'OAI handler OAI protocol and mapping support responds to a GetRecord request for type oai_ead, mapping appropriately',
   'EAD3 export mappings',
  ]

RSpec.configure do |config|
  config.around(:each) do |example|
    example.run unless disabled_tests.any?{|dt| example.full_description.start_with?(dt)}
  end
end
