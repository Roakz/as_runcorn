ArchivalObjectsController.class_eval do
  # Support 'clone_from_uri' when creating a new archival object
  # and ensure that all readonly properties (and ref_id) are dropped
  # from the source JSONModel.

  alias :new_pre_as_runcorn :new
  def new
    if inline? && params[:clone_from_uri]
      parsed_uri = JSONModel.parse_reference(params[:clone_from_uri])

      if parsed_uri[:type] != 'archival_object'
        raise 'Can only clone from an archival object'
      end

      source = JSONModel(:archival_object).find(parsed_uri[:id], find_opts)

      hash = source.to_hash(:trusted)
      sanitised_hash = JSONSchemaUtils.map_hash_with_schema(hash, JSONModel(:archival_object).schema,
                                                            [proc { |hash, schema|
                                                               hash = hash.clone
                                                               schema['properties'].each do |name, properties|
                                                                 if name == 'ref_id'
                                                                   hash.delete(name)
                                                                 elsif properties['readonly'] && name != '_resolved'
                                                                   hash.delete(name)
                                                                 end
                                                               end
                                                               hash
                                                             }])

      @archival_object = JSONModel(:archival_object).from_hash(sanitised_hash, false, true)

      return render_aspace_partial :partial => 'archival_objects/new_inline'
    else
      new_pre_as_runcorn
    end
  end

  include ExportHelper

  def index
    (search_params, expiring_within) = build_search_params

    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], ["archival_object"], search_params)

        # If we dropped the filter_term out, add it back so the results page looks right.
        if expiring_within
          @search_data[:criteria]['filter_term[]'] << expiring_within
        end
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => []})
        search_params["type[]"] = ["archival_object"]
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), 'items.' )
      }
    end
  end


  def build_search_params
    search_params = params_for_backend_search.merge("facet[]" => SearchResultData.ARCHIVAL_OBJECT_FACETS)

    expiring_days = nil

    expiring_within = nil

    if search_params['filter_term[]']
      if expiring_within = search_params['filter_term[]'].find {|term| JSON.parse(term).keys[0] == 'rap_expiring_within'}
        search_params['filter_term[]'].delete(expiring_within)

        expiring_days = JSON.parse(expiring_within).values[0]
      end
    end

    if expiring_days
      start_date, end_date = [Date.today, Date.today + expiring_days].sort

      query = {'query' => {
                 'jsonmodel_type' => 'boolean_query',
                 'op' => 'AND',
                 'subqueries' => [
                   {
                     'jsonmodel_type' => 'date_field_query',
                     'comparator' => 'greater_than',
                     'field' => 'rap_expiry_date_sort_u_ssortdate',
                     'value' => "%sT00:00:00Z" % [start_date.iso8601],
                   },
                   {
                     'jsonmodel_type' => 'date_field_query',
                     'comparator' => 'lesser_than',
                     'field' => 'rap_expiry_date_sort_u_ssortdate',
                     'value' => "%sT00:00:00Z" % [end_date.iso8601],
                   }
                 ]
               }
              }

      search_params['filter'] = JSONModel(:advanced_query).from_hash(query).to_json
    end

    [search_params, expiring_within]
  end


end
