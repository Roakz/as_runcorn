class SignificantItems

  def self.list(opts = {})
    opts[:level] ||= 'all'

    ds = base_query.limit(opts[:page_size], ((opts[:page] - 1) * opts[:page_size]))

    ds = if opts[:level] == 'all'
           ds.filter(Sequel.~(:significance__value => 'standard'))
         else
           ds.filter(:significance__value => opts[:level])
         end

    if opts[:series]
      ds = ds.filter(:resource__id => opts[:series].map{|uri| JSONModel.parse_reference(uri).fetch(:id)})
    end

    if opts[:location]
      ds = add_location_filter(ds, opts[:location])
    end

    ds.map{|row| format(row)}
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
        :label => (row[:tcon_type] ? I18n.t('enumerations.container_type.' + row[:tcon_type]) + ': ' : '') + (row[:tcon_indicator] || '-- NO INDICATOR --'),
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


  def self.add_location_filter(ds, location)
    loc_uri = JSONModel.parse_reference(location)

    if loc_uri
      ds.filter(:prep_fn_loc__value => 'HOME', :tcon_fn_loc__value => 'HOME', :location_id => loc_uri[:id])
    else
      ds.filter(:prep_fn_loc__value => 'HOME', :tcon_fn_loc__value => location)
        .or(:prep_fn_loc__value => location)
    end
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
        .reverse(:significance__position)
        .select(
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
end
