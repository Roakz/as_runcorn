ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'as_runcorn',
      'physical_representations',
      ['resource', 'archival_object'],
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
      ['resource', 'archival_object'],
      {
        template_name: 'digital_representation',
        js_edit_template_name: 'template_digital_representation',
        heading_text:  I18n.t('digital_representation._plural'),
        sidebar_label:  I18n.t('digital_representation._plural'),
      }
    )
  )

  Plugins.add_resolve_field(['approved_by', 'container'])

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
end
