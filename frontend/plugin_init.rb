ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative 'helpers/user_helper'
require_relative 'helpers/qsa_id_helper'
require_relative 'helpers/significance_helper'
require_relative 'helpers/field_helper'

Rails.application.config.after_initialize do

  # Override #checkbox to to ensure users without the 'manage_publication'
  # permission can't change publish flags. Doing it this way to avoid having
  # to override lots and lots of templates.
  module AspaceFormHelper
    class FormContext
      alias_method :checkbox_orig, :checkbox

      def checkbox(name, opts = {}, default = true, force_checked = false)
        # FIXME: sheesh, there must be a better way!
        parent = self.instance_variable_get(:'@parent')

        unless name == 'publish' && !parent.user_can?('update_publish_flag')
          return checkbox_orig(name, opts, default, force_checked)
        end

        options = {:id => "#{id_for(name)}", :type => "hidden", :name => path(name), :value => obj[name] ? 1 : 0}
        @forms.tag("input", options) + I18n.t("boolean.#{obj[name]}")
      end
    end
  end

  MemoryLeak::Resources.define(:batch_action_types, proc { JSONModel::HTTP.get_json('/batch_action_handler/action_types') }, 60)

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
       'mandate', 'digital_representation', 'physical_representation', 'assessment',
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

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'as_runcorn',
      'conservation_treatments',
      ['physical_representation'],
      {
        template_name: 'conservation_treatment',
        js_edit_template_name: 'template_conservation_treatment',
        heading_text:  I18n.t('conservation_treatments._plural'),
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

    def render_edit(view_context, record, form_context)
      view_context.readonly_context record['jsonmodel_type'], record do |readonly_context|
        render_readonly(view_context, record, readonly_context)
      end
    end

    def supports?(record, mode)
      return false unless @jsonmodel_types.include?(record['jsonmodel_type'])
      # don't show on forms for new records 
      return false if record['uri'].nil? && record['existing_ref'].nil?

      super
    end

    private

    def parse_opts(opts)
      super

      @show_on_edit = true
      @show_on_readonly = true
      @heading_text = opts.fetch(:heading_text)
      @erb_template = opts.fetch(:erb_template)
    end
  end


  Plugins.register_plugin_section(
    RAPSection.new(
      'as_runcorn',
      'rap_attached',
      ['resource'],
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
      ['physical_representation', 'digital_representation', 'archival_object'],
      {
        erb_template: 'rap_applied/show_as_subrecords',
        heading_text:  I18n.t('rap_applied._plural'),
        sidebar_label:  I18n.t('rap_applied._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    RAPSection.new(
      'as_runcorn',
      'rap_summary',
      ['resource'],
      {
        erb_template: 'raps_summary/show_as_subrecords',
        heading_text:  I18n.t('rap_summary.heading'),
        sidebar_label:  I18n.t('rap_summary.heading'),
      }
    )
  )


  Plugins.add_resolve_field(['approved_by',
                             'container',
                             'transfer',
                             'service_items',
                             'storage_location',
                             'move_context',
                             'movements::user',
                             'rap_history',
                             'attached_to',
                             'rap_history::attached_to',
                             'user',
                             'assessment'])

  Plugins.add_search_base_facets("representation_intended_use_u_sstr",
                                 "rap_access_status_u_ssort",
                                 "publish",
                                 "archivist_approved_u_sbool")

  Plugins.add_facet_group_i18n("archivist_approved_u_sbool",
                               proc {|facet| "boolean.#{facet}" })

  Plugins.add_facet_group_i18n("representation_intended_use_u_sstr",
                               proc {|facet| "enumerations.runcorn_intended_use.#{facet}" })

  Plugins.add_facet_group_i18n("significance_u_sstr",
                               proc {|facet| "enumerations.runcorn_significance.#{facet}" })

  # Show a new search facet for our category
  Plugins.add_search_facets(:agent_corporate_entity, "agency_category_u_sstr")

  Plugins.add_facet_group_i18n("agency_category_u_sstr",
                               proc {|facet| "enumerations.agency_category.#{facet}" })

  Plugins.add_search_facets(:batch, "batch_status_u_ssort")
  Plugins.add_facet_group_i18n("batch_status_u_ssort",
                               proc {|facet| "enumerations.runcorn_batch_status.#{facet}" })

  Plugins.add_facet_group_i18n('item_use_status_u_ssort',
                               proc {|facet| "reading_room_requests.statuses.#{facet}" })
  Plugins.add_facet_group_i18n('item_use_type_u_ssort',
                               proc {|facet| "item_use.item_use_type_values.#{facet}" })

  # Eager load all JSON schemas
  Dir.glob(File.join(File.dirname(__FILE__), "..", "schemas", "*.rb")).each do |schema|
    next if schema.end_with?('_ext.rb')
    JSONModel(File.basename(schema, ".rb").intern)
  end


  SearchHelper

  # register qsa_id models
  require_relative '../common/qsa_id'
  QSAId.mode(:frontend)
  require_relative '../common/qsa_id_registrations'

  # allow other plugins to add models as movement contexts
  require_relative '../common/movement_context_manager'

  # make sure the identifier column in search results shows qsa_ids where they exist
  module SearchHelper
    alias :identifier_for_search_result_orig :identifier_for_search_result

    def identifier_for_search_result(result)
      if QSAId.models.include?(result["primary_type"].intern)
        if result.has_key? 'qsa_id_u_ssort'
          identifier = result['qsa_id_u_ssort']
        else
          json       = ASUtils.json_parse(result["json"])
          identifier = json.fetch('qsa_id_prefixed', "")
        end
        QSAIdHelper.id(identifier)
      else
        identifier_for_search_result_orig(result)
      end
    end
  end

  require_relative '../common/validations'

  require_relative 'reformulator_configuration'

  # Override application_controller.find_opts to be more selective when
  # resolving for a record
  class ApplicationController
    alias :as_runcorn_find_opts_orig :find_opts
    def find_opts
      if controller_name == 'archival_objects'
        if ['show', 'edit', 'update'].include?(action_name)
          result = as_runcorn_find_opts_orig.clone
          result.fetch('resolve[]').reject!{|field| field == 'resource'}
          return result
        end
      end

      as_runcorn_find_opts_orig
    end
  end

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


  ActiveSupport::Reloader.to_complete do
    # Make sure our extensions get loaded *after* other files get reloaded
    Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'controllers/*_ext.rb')).each do |controller_extension|
      load controller_extension
    end

  end

  Plugins.register_note_types_handler(proc {|jsonmodel_type, note_types, context|
    if jsonmodel_type.to_s =~ /agent/
      note_types = context.singlepart_notes
    end

    note_types
  })
end
