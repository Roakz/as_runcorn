Reformulator.configure(
  {
    # Rules here apply to any controller and any section
    "_global" => {
      "hideFields" => [
        {
          "selector" => 'select#event_chronotype_label_',
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'select[name*="[label]"]',
          "nameMustMatchRegex" => "date.*\\[label\\]",
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'select[name*="[era]"]',
          "nameMustMatchRegex" => "date.*\\[era\\]",
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'select[name*="[calendar]"]',
          "nameMustMatchRegex" => "date.*\\[calendar\\]",
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'textarea[name*="[expression]"]',
          "nameMustMatchRegex" => "date.*\\[expression\\]",
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'select[name*="[date_type]"]',
          "nameMustMatchRegex" => "date.*\\[date_type\\]",
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'select[name="resource[resource_type]"]',
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'select[name="resource[level]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => '.extent-calculator-btn',
        },
        {
          "selector" => 'input[name="archival_object[component_id]"]',
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => 'textarea[name="archival_object[repository_processing_note]"]',
          "hideClosestSelector" => '.form-group',
        },
        {
          "selector" => '#resource_form select[name^="resource[dates]["][name$="][label]"] option:not([value="existence"])',
          "hideClosestSelector" => 'option'
        },
        {
          "selector" => 'select[name*="[deaccessions]"][name$="[scope]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'select[name*="[deaccessions]"][name$="[date][label]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'input[name*="[deaccessions]"][name$="[date][end]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'select[name*="[deaccessions]"][name$="[date][certainty_end]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'input[name="location[temporary_question]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'select[name="location[temporary]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'input[name="location_batch[temporary_question]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'select[name="location_batch[temporary]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'input[name="top_container[ils_holding_id]"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'label[for="top_container_ils_item_id_"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'label[for="top_container_exported_to_ils_"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'select[name="exported"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'label[for="collection_accession"]',
          "hideClosestSelector" => '.form-group'
        },
        {
          "selector" => 'input[name^="agent[agent_contacts]"]',
          "nameMustMatchRegex" => ".*\\[telephones\\]\\[[0-9]+\\]\\[ext\\]",
          "hideClosestSelector" => ".form-group"
        }
      ],
      "defaultValues" => [
        {
          "selector" => 'select#event_chronotype_label_',
          "value" => 'timestamp',
        },
        {
          "selector" => 'select[name*="[date_type]"]',
          "nameMustMatchRegex" => "date.*\\[date_type\\]",
          "nameMustNotMatchRegex" => "(dates_of_existence|(mandate|function|event)\\[date\\])",
          "value" => 'inclusive',
        },
        {
          "selector" => 'select[name*="[date_type]"]',
          "nameMustMatchRegex" => "(dates_of_existence|mandate|function).*\\[date_type\\]",
          "value" => 'range',
        },
        {
          "selector" => 'select[name*="[dates]"][name*="[label]"]',
          "value" => 'existence',
        },
        {
          "selector" => 'select[name="resource[level]"]',
          "value" => 'series',
        },
        {
          "selector" => 'input[name="resource[language]"]',
          "value" => 'eng',
        },
        {
            "selector" => 'select[name="archival_object[level]"]',
            "value" => 'item',
        },
        {
          "selector" => 'select[name="archival_object[language]"]',
          "value" => 'eng',
        },
        {
          "selector" => 'input[name^="archival_object[physical_representations]"]',
          "nameMustMatchRegex" => ".*\\[title\\]",
          "valueSelector" => 'textarea[name="archival_object[title]"]',
          "onlyIfEmpty" => true,
        },
        {
          "selector" => 'input[name^="archival_object[digital_representations]"]',
          "nameMustMatchRegex" => ".*\\[title\\]",
          "valueSelector" => 'textarea[name="archival_object[title]"]',
          "onlyIfEmpty" => true,
        },
        {
          "selector" => '#resource_form select[name^="resource[dates]["][name$="][label]"]',
          "value" => 'existence'
        },
        {
          "selector" => 'select[name*="[deaccessions]"][name$="[scope]"]',
          "value" => 'whole'
        },
        {
          "selector" => 'select[name*="[deaccessions]"][name$="[date][label]"]',
          "value" => 'deaccession'
        },
        {
          "selector" => 'input[name="location[coordinate_1_label]"]',
          "value" => 'Row'
        },
        {
          "selector" => 'input[name="location[coordinate_2_label]"]',
          "value" => 'Press'
        },
        {
          "selector" => 'input[name="location[coordinate_3_label]"]',
          "value" => 'Bay'
        },
        {
          "selector" => 'input[name="location_batch[coordinate_1_label]"]',
          "value" => 'Row'
        },
        {
          "selector" => 'input[name="location_batch[coordinate_2_label]"]',
          "value" => 'Press'
        },
        {
          "selector" => 'input[name="location_batch[coordinate_3_label]"]',
          "value" => 'Bay'
        },
      ],
    },

    "resources" => {
      "resource_related_accessions_" => {
        "show" => [],
      },
      "finding_aid" => {
        "show" => [],
      },
      "resource_linked_agents_" => {
        "show" => [],
      },
      "resource_extents_" => {
        "show" => [],
        "defaultValues" => [
          {"path" => ["resource_extents_", "_number_"], "value" => "0"},
          {"path" => ["resource_extents_", "_extent_type_"], "value" => "volumes"},
          ]
        },
      "archival_object_linked_agents_" => {
        "show" => [],
      },
      "archival_object_extents_" => {
        "show" => [],
        "defaultValues" => [
          {"path" => ["archival_object_extents_", "_number_"], "value" => "0"},
          {"path" => ["archival_object_extents_", "_extent_type_"], "value" => "volumes"},
        ]
      },
      "resource_instances_" => {
        "show" => [],
      },
      "archival_object_instances_" => {
        "show" => [],
      },
      "container_locations" => {
        "show" => [],
      },
      "basic_information" => {
        "fieldMoves" => [
          {"path" => ["resource", "_abstract_"], "moveAfter" => "_title_"},
          {"path" => ["resource", "_archivist_approved_"], "moveAfter" => "_repository_processing_note_"}
        ]
      },
      "resource_rights_statements_" => {
        "show" => []
      },
      "resource_collection_management_" => {
        "show" => []
      },
      "resource_classifications_" => {
        "show" => []
      },
      "resource_user_defined_" => {
        "show" => []
      },
    },

    "agents" => {
      "agent_corporate_entity_related_agents" => {
        "show" => [],
      },
      "agent_corporate_entity_names" => {
        "show" => [
          ["agent_names_", "_primary_name_"],
          ["agent_names_", "_subordinate_name_1_"],
          ["agent_names_", "_subordinate_name_2_"]
        ],
        "defaultValues" => [
          { "path" => ["agent_names_", "_source_"], "value" => "local" }
        ],
        "moveSectionAfter" => "basic_information",
      },
      "agent_corporate_entity_dates_of_existence" => {
        "show" => [
          ["agent_dates_of_existence_", "_begin_"],
          ["agent_dates_of_existence_", "_certainty_"],
          ["agent_dates_of_existence_", "_end_"],
          ["agent_dates_of_existence_", "_certainty_end_"],
          ["agent_dates_of_existence_", "_date_notes_"]
        ],
        "defaultValues" => [
          {"path" => ["agent_dates_of_existence_", "_date_type_"], "value" => "range"}
        ]
      }
    },

    "top_containers" => {
      "container_locations" => {
        "show" => [],
      },

    }
  }
)
