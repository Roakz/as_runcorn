AdvancedSearch.define_field(:name => 'deaccessioned', :type => :boolean, :visibility => [:staff], :solr_field => 'deaccessioned_u_sbool')
AdvancedSearch.define_field(:name => 'identifier', :type => :text, :visibility => [:staff, :public], :solr_field => 'qsa_id_u_stext')
AdvancedSearch.define_field(:name => 'runcorn_location', :type => :enum, :visibility => [:staff, :public], :solr_field => 'current_location_u_sstr')
