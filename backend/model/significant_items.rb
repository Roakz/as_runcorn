class SignificantItems

  PAGE_SIZE = AppConfig.has_key?(:significant_items_page_size) ? AppConfig[:significant_items_page_size] : 100


  def self.list(opts = {})
    opts[:level] ||= 'all'

    query = AdvancedQueryBuilder.new
    query = query.and('primary_type', 'physical_representation', 'text', literal = true)


    if opts[:level] == 'all'
      query = query.and('significance_u_sstr', 'standard', 'text', literal = true, negated = true)
    else
      query = query.and('significance_u_sstr', opts[:level], 'text', literal = true, negated = false)
    end

    if opts[:series]
      query = query.and('controlling_record_series_u_sstr', opts[:series][0], 'text', literal = true)
    end

    if opts[:location]
      loc_uri = JSONModel.parse_reference(opts[:location])

      location_query = AdvancedQueryBuilder.new

      if loc_uri
        location_query = location_query
                           .and('current_location_u_sstr', 'HOME', 'text', literal = true)
                           .and('top_container_location_u_sstr', 'HOME', 'text', literal = true)
                           .and('top_container_home_location_uri_u_sstr', opts[:location], 'text', literal = true)
      else
        box_moved = AdvancedQueryBuilder.new
                      .and('current_location_u_sstr', 'HOME', 'text', literal = true)
                      .and('top_container_location_u_sstr', opts[:location], 'text', literal = true)

        location_query = location_query.and(box_moved).or('current_location_u_sstr', opts[:location], 'text', literal = true)
      end

      query = query.and(location_query)
    end

    counts_query = Solr::Query.create_match_all_query
                     .set_filter(query.build)

    levels = BackendEnumSource.values_for('runcorn_significance').reject{|level| level == 'standard'}.reverse

    level_counts = Solr.search(counts_query
                                 .set_facets('significance_u_sstr')
                                 .pagination(1, 1))
                     .dig('facets', 'facet_fields', 'significance_u_sstr')
                     .each_slice(2)
                     .to_h

    total = level_counts.values.reduce{|a,b| a+b}
    pages = (total.to_f / PAGE_SIZE).ceil

    running_count = 0
    first_pages = levels.map{|level|
      count = level_counts.fetch(level, 0)
      running_count += count
      [level, ((1.0 + running_count - count)/PAGE_SIZE).ceil]
    }.to_h


    page_query = Solr::Query.create_match_all_query
                   .set_filter(query.build)
                   .set_field_list(['uri'])
                   .set_sort(build_level_sort('significance_u_sstr', levels) + " desc,qsa_id_u_sort asc")
                   .pagination(opts[:page], PAGE_SIZE)

    physrep_ids = Solr.search(page_query).fetch('results', []).map {|result| JSONModel.parse_reference(result.fetch('uri')).fetch(:id)}

    {
      :counts => {
        :total => total,
        :pages => pages,
        :page_size => PAGE_SIZE,
        :first_page_for_levels => first_pages,
        :levels => level_counts
      },
      :items => selects(base_query.filter(Sequel.qualify(:physical_representation, :id) => physrep_ids))
                  .all
                  .sort_by {|row| physrep_ids.index(row[:prep_id])}
                  .map {|row| format(row) },
    }
  end


  # NOTE: Levels expected to be sorted most important to least important
  #
  # Returns a Solr FunctionQuery that returns progressively smaller numbers for
  # each level.
  def self.build_level_sort(field, levels)
    result = ""

    levels.reverse.each_with_index do |level, idx|
      if idx == 0
        result = "if(termfreq(#{field},\"#{level}\"),#{idx + 1},0)"
      else
        result = "if(termfreq(#{field},\"#{level}\"),#{idx + 1},#{result})"
      end
    end

    result
  end

  def self.format(row)
    {
      :significance => row[:prep_significance],
      :qsa_id => QSAId.prefixed_id_for(PhysicalRepresentation, row[:prep_qsa_id]),
      :label => row[:prep_label],
      :format => row[:prep_format],
      :current_location => current_location_for(row),
      :functional_location => row[:prep_fn_loc],
      :uri => JSONModel::JSONModel(:physical_representation).uri_for(row[:prep_id], :repo_id => row[:repo_id]),
      :container => {
        :qsa_id => QSAId.prefixed_id_for(TopContainer, row[:tcon_qsa_id]),
        :label => (row[:tcon_type] ? I18n.t('enumerations.container_type.' + row[:tcon_type], :default => row[:tcon_type]) + ': ' : '') + (row[:tcon_indicator] || '-- NO INDICATOR --'),
        :functional_location => row[:tcon_fn_loc],
        :uri => JSONModel::JSONModel(:top_container).uri_for(row[:tcon_id], :repo_id => row[:repo_id]),
        :storage_location => {
          :label => row[:loc_label],
          :uri => row[:loc_id] ? JSONModel::JSONModel(:location).uri_for(row[:loc_id], :repo_id => row[:repo_id]) : false,
        }
      },
      :record => {
        :qsa_id => QSAId.prefixed_id_for(ArchivalObject, row[:record_qsa_id]),
        :label => row[:record_label],
        :uri => JSONModel::JSONModel(:archival_object).uri_for(row[:record_id], :repo_id => row[:repo_id]),
      },
      :series => {
        :qsa_id => QSAId.prefixed_id_for(Resource, row[:series_qsa_id]),
        :label => row[:series_label],
        :uri => JSONModel::JSONModel(:resource).uri_for(row[:series_id], :repo_id => row[:repo_id]),
      }
    }
  end


  def self.current_location_for(row)
    out = {:uri => false, :in_container => false}
    if row[:prep_fn_loc] == 'HOME'
      out[:in_container] = true
      if row[:tcon_fn_loc] == 'HOME'
          out[:location] = row[:loc_label]
          out[:uri] = JSONModel::JSONModel(:location).uri_for(row[:loc_id], :repo_id => row[:repo_id]) if row[:loc_id]
      else
        out[:location] = row[:tcon_fn_loc]
      end
    else
      out[:location] = row[:prep_fn_loc]
    end
    out
  end


  def self.base_query
    DB.open do |db|
      db[:physical_representation]
        .left_join(Sequel.as(:enumeration_value, :significance), :significance__id => :physical_representation__significance_id)
        .left_join(Sequel.as(:enumeration_value, :prep_fn_loc), :prep_fn_loc__id => :physical_representation__current_location_id)
        .left_join(Sequel.as(:enumeration_value, :prep_format), :prep_format__id => :physical_representation__format_id)
        .left_join(:representation_container_rlshp, :representation_container_rlshp__physical_representation_id => :physical_representation__id)
        .left_join(:top_container, :top_container__id => :representation_container_rlshp__top_container_id)
        .left_join(:top_container_housed_at_rlshp, :top_container_housed_at_rlshp__top_container_id => :top_container__id)
        .left_join(Sequel.as(:enumeration_value, :tcon_fn_loc), :tcon_fn_loc__id => :top_container__current_location_id)
        .left_join(Sequel.as(:enumeration_value, :tcon_type), :tcon_type__id => :top_container__type_id)
        .left_join(:location, :location__id => :top_container_housed_at_rlshp__location_id)
        .left_join(:archival_object, :archival_object__id => :physical_representation__archival_object_id)
        .left_join(:resource, :resource__id => :archival_object__root_record_id)
        .filter(Sequel.|({:top_container_housed_at_rlshp__status => 'current'}, {:top_container_housed_at_rlshp__status => nil}))
    end
  end


  def self.selects(ds)
    ds.select(
              Sequel.as(:physical_representation__repo_id, :repo_id),
              Sequel.as(:physical_representation__id, :prep_id),
              Sequel.as(:physical_representation__qsa_id, :prep_qsa_id),
              Sequel.as(:physical_representation__title, :prep_label),
              Sequel.as(:significance__value, :prep_significance),
              Sequel.as(:prep_fn_loc__value, :prep_fn_loc),
              Sequel.as(:prep_format__value, :prep_format),
              Sequel.as(:top_container__id, :tcon_id),
              Sequel.as(:top_container__indicator, :tcon_indicator),
              Sequel.as(:top_container__id, :tcon_qsa_id),
              Sequel.as(:tcon_fn_loc__value, :tcon_fn_loc),
              Sequel.as(:tcon_type__value, :tcon_type),
              Sequel.as(:location__id, :loc_id),
              Sequel.as(:location__title, :loc_label),
              Sequel.as(:archival_object__id, :record_id),
              Sequel.as(:archival_object__qsa_id, :record_qsa_id),
              Sequel.as(:archival_object__display_string, :record_label),
              Sequel.as(:resource__id, :series_id),
              Sequel.as(:resource__qsa_id, :series_qsa_id),
              Sequel.as(:resource__title, :series_label)
              )
  end
end

=begin

Here is the raw SQL to get all non-standard significant items, with all the necessary columns

SELECT `physical_representation`.`repo_id` AS `repo_id`,
       `physical_representation`.`id` AS `prep_id`,
       `physical_representation`.`qsa_id` AS `prep_qsa_id`,
       `physical_representation`.`title` AS `prep_label`,
       `significance`.`value` AS `prep_significance`,
       `prep_fn_loc`.`value` AS `prep_fn_loc`,
       `prep_format`.`value` AS `prep_format`,
       `top_container`.`id` AS `tcon_id`,
       `top_container`.`indicator` AS `tcon_indicator`,
       `top_container`.`id` AS `tcon_qsa_id`,
       `tcon_fn_loc`.`value` AS `tcon_fn_loc`,
       `tcon_type`.`value` AS `tcon_type`,
       `location`.`id` AS `loc_id`,
       `location`.`title` AS `loc_label`,
       `archival_object`.`id` AS `record_id`,
       `archival_object`.`qsa_id` AS `record_qsa_id`,
       `archival_object`.`display_string` AS `record_label`,
       `resource`.`id` AS `series_id`,
       `resource`.`qsa_id` AS `series_qsa_id`,
       `resource`.`title` AS `series_label`
FROM `physical_representation`
LEFT JOIN `enumeration_value` AS `significance` ON (`significance`.`id` = `physical_representation`.`significance_id`)
LEFT JOIN `enumeration_value` AS `prep_fn_loc` ON (`prep_fn_loc`.`id` = `physical_representation`.`current_location_id`)
LEFT JOIN `enumeration_value` AS `prep_format` ON (`prep_format`.`id` = `physical_representation`.`format_id`)
LEFT JOIN `representation_container_rlshp` ON (`representation_container_rlshp`.`physical_representation_id` = `physical_representation`.`id`)
LEFT JOIN `top_container` ON (`top_container`.`id` = `representation_container_rlshp`.`top_container_id`)
LEFT JOIN `top_container_housed_at_rlshp` ON (`top_container_housed_at_rlshp`.`top_container_id` = `top_container`.`id`)
LEFT JOIN `enumeration_value` AS `tcon_fn_loc` ON (`tcon_fn_loc`.`id` = `top_container`.`current_location_id`)
LEFT JOIN `enumeration_value` AS `tcon_type` ON (`tcon_type`.`id` = `top_container`.`type_id`)
LEFT JOIN `location` ON (`location`.`id` = `top_container_housed_at_rlshp`.`location_id`)
LEFT JOIN `archival_object` ON (`archival_object`.`id` = `physical_representation`.`archival_object_id`)
LEFT JOIN `resource` ON (`resource`.`id` = `archival_object`.`root_record_id`)
WHERE (((`top_container_housed_at_rlshp`.`status` = 'current') OR (`top_container_housed_at_rlshp`.`status` IS NULL))
AND (`significance`.`value` != 'standard')) ORDER BY `significance`.`position` DESC

=end

