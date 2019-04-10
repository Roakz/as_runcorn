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
       'mandate',
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

  # Show a new search facet for our category
  Plugins.add_search_facets(:agent_corporate_entity, "agency_category_u_sstr")

  Plugins.add_facet_group_i18n("agency_category_u_sstr",
                               proc {|facet| "enumerations.agency_category.#{facet}" })

  # Force load
  JSONModel(:physical_representation)
  JSONModel(:digital_representation)

  # register qsa_id models
  require_relative '../common/qsa_id'
  QSAId.mode(:frontend)
  require_relative '../common/qsa_id_registrations'

  # make sure the identifier column in search results shows qsa_ids where they exist
  module SearchHelper
    alias :identifier_for_search_result_orig :identifier_for_search_result

    def identifier_for_search_result(result)
      if QSAId.models.include?(result["primary_type"].intern)
        if result.has_key? 'qsa_id__u_sint'
          identifier = result['qsa_id__u_sint'].first
        else
          json       = ASUtils.json_parse(result["json"])
          identifier = json.fetch('qsa_id', "")
        end
        identifier.to_s.html_safe
      else
        identifier_for_search_result_orig(result)
      end
    end
  end

  require_relative '../common/validation_overrides'

  require_relative 'reformulator_configuration'
end
