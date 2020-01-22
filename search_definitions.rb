require_relative 'common/date_range_overlap'

AdvancedSearch.define_field(:name => 'deaccessioned', :type => :boolean, :visibility => [:staff], :solr_field => 'deaccessioned_u_sbool')
AdvancedSearch.define_field(:name => 'identifier', :type => :text, :visibility => [:staff], :solr_field => 'qsa_id_u_stext')
AdvancedSearch.define_field(:name => 'runcorn_location', :type => :enum, :visibility => [:staff], :solr_field => 'current_location_u_sstr')
AdvancedSearch.define_field(:name => 'conservation_treatment', :type => :text, :visibility => [:staff], :solr_field => 'conservation_treatment_u_stext')
AdvancedSearch.define_field(:name => 'top_container_identifier', :type => :range, :visibility => [:staff], :solr_field => 'top_container_identifier_u_ssort')
AdvancedSearch.define_field(:name => 'agency_assigned_id', :type => :text, :visibility => [:staff], :solr_field => 'agency_assigned_id_u_stext', :solr_field_exact_match => 'agency_assigned_id_u_sort')
AdvancedSearch.define_field(:name => 'runcorn_format', :type => :enum, :visibility => [:staff], :solr_field => 'representation_format_u_sstr')
AdvancedSearch.define_field(:name => 'archivist_approved', :type => :boolean, :visibility => [:staff], :solr_field => 'archivist_approved_u_sbool')
AdvancedSearch.define_field(:name => 'is_open_access', :type => :boolean, :visibility => [:staff], :solr_field => 'rap_is_open_access_u_sbool')
AdvancedSearch.remove_field('suppressed')
AdvancedSearch.define_field(:name => 'date', :type => :range, :visibility => [:staff], :solr_field => DateRangeOverlap.new('date_start_u_ssort', 'date_end_u_ssort'))
AdvancedSearch.remove_field('creators')
