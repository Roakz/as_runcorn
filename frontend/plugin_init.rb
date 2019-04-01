ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'as_runcorn',
      'physical_representations',
      ['archival_object'],
      {
        template_name: 'physical_representation',
        js_edit_template_name: 'template_physical_representation',
        heading_text:  I18n.t('physical_representation._plural'),
        sidebar_label:  I18n.t('physical_representation._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'as_runcorn',
      'digital_representations',
      ['archival_object'],
      {
        template_name: 'digital_representation',
        js_edit_template_name: 'template_digital_representation',
        heading_text:  I18n.t('digital_representation._plural'),
        sidebar_label:  I18n.t('digital_representation._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'as_runcorn',
      'external_ids',
      ['accession', 'resource', 'archival_object',
       'collection_management', 'event', 'location', 'subject',
       'agent_corporate_entity', 'agent_person', 'agent_family', 'agent_software',
       'mandate', 'function'
      ],
      {
        template_name: 'external_id',
        js_edit_template_name: 'template_external_id',
        heading_text:  I18n.t('external_id._plural'),
        sidebar_label:  I18n.t('external_id._plural'),
      }
    )
  )


  Plugins.add_resolve_field(['approved_by', 'container', 'related_accession'])

  Plugins.add_facet_group_i18n("representation_intended_use_u_sstr",
                               proc {|facet| "enumerations.runcorn_intended_use.#{facet}" })

  # Force load
  JSONModel(:physical_representation)
  JSONModel(:digital_representation)

  # register qsa_id models
  QSAId.register(:resource, :id_0)
  QSAId.register(:archival_object, :ref_id)
  QSAId.register(:digital_object, :digital_object_id)
  QSAId.register(:function)
  QSAId.register(:mandate)
  QSAId.register(:accession, :id_0)
  QSAId.register(:agent_corporate_entity)
  QSAId.register(:physical_representation)
  QSAId.register(:digital_representation)

  require_relative '../common/validation_overrides'
end
