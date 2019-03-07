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
end
