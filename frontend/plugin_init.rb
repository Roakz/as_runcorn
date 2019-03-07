ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'series_system',
      'physical_representation',
      ['resource', 'archival_object'],
      {
        template_name: 'physical_representation',
        heading_text:  I18n.t('physical_representation._singular'),
      }
    )
  )
end
