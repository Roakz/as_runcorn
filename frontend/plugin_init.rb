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
       'mandate', 'digital_representation', 'physical_representation',
      ],
      {
        template_name: 'external_id',
        js_edit_template_name: 'template_external_id',
        heading_text:  I18n.t('external_id._plural'),
        sidebar_label:  I18n.t('external_id._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'as_runcorn',
      'deaccessions',
      ['archival_object'],
      {
        template_name: 'deaccession',
        js_edit_template_name: 'template_deaccession',
        heading_text:  I18n.t('deaccession._plural'),
        sidebar_label:  I18n.t('deaccession._plural'),
        erb_readonly_template_path: 'deaccessions/show',
      }
    )
  )


  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'as_runcorn',
      'movements',
      ['physical_representation', 'top_container'],
      {
        template_name: 'movement',
        js_edit_template_name: 'template_movement',
        heading_text:  I18n.t('movement._plural'),
        sidebar_label:  I18n.t('movement._plural'),
      }
    )
  )

  class RAPSection < Plugins::AbstractPluginSection
    def render_readonly(view_context, record, form_context)
      view_context.render_aspace_partial(
        :partial => @erb_template,
        :locals => {
          :record => record,
          :heading_text => @heading_text,
          :section_id => @section_id ? @section_id : build_section_id(form_context.obj['jsonmodel_type']),
          :form => form_context,
        }
      )
    end

    private

    def parse_opts(opts)
      super

      @show_on_edit = false
      @heading_text = opts.fetch(:heading_text)
      @erb_template = opts.fetch(:erb_template)
    end
  end


  Plugins.register_plugin_section(
    RAPSection.new(
      'as_runcorn',
      'rap_attached',
      ['archival_object', 'physical_representation', 'digital_representation'],
      {
        erb_template: 'rap_attached/show_as_subrecords',
        heading_text:  I18n.t('rap_attached._plural'),
        sidebar_label:  I18n.t('rap_attached._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    RAPSection.new(
      'as_runcorn',
      'rap_applied',
      ['physical_representation', 'digital_representation'],
      {
        erb_template: 'rap_applied/show_as_subrecords',
        heading_text:  I18n.t('rap_applied._plural'),
        sidebar_label:  I18n.t('rap_applied._plural'),
      }
    )
  )


  Plugins.add_resolve_field(['approved_by',
                             'container',
                             'transfer',
                             'service_items',
                             'storage_location',
                             'move_context',
                             'rap_history'])

  Plugins.add_facet_group_i18n("representation_intended_use_u_sstr",
                               proc {|facet| "enumerations.runcorn_intended_use.#{facet}" })

  # Show a new search facet for our category
  Plugins.add_search_facets(:agent_corporate_entity, "agency_category_u_sstr")

  Plugins.add_facet_group_i18n("agency_category_u_sstr",
                               proc {|facet| "enumerations.agency_category.#{facet}" })

  # Force load
  JSONModel(:physical_representation)
  JSONModel(:digital_representation)
  JSONModel(:chargeable_item)
  JSONModel(:chargeable_service)
  SearchHelper

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

  require_relative '../common/validations'

  require_relative 'reformulator_configuration'

  begin
    HistoryController.add_skip_field('move_to_storage_permitted')
    HistoryController.add_skip_field('normal_location')
    HistoryController.add_skip_field('container_locations')
    HistoryController.add_skip_field('context_uri')
    HistoryController.add_skip_field('existing_ref')
    HistoryController.add_enum_handler {|type, field|
      if ['physical_representation', 'movement', 'top_container', 'absent_content'].include?(type) &&
          ['current_location', 'normal_location', 'functional_location'].include?(field)
        'runcorn_location'
      elsif type == 'physical_representation' && field == 'contained_within'
        'runcorn_physical_representation_contained_within'
      elsif type == 'digital_representation' && field == 'contained_within'
        'runcorn_digital_representation_contained_within'
      end
    }
  rescue NameError
    # never mind
  end

end
