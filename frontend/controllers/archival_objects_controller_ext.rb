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
    respond_to do |format|
      format.html {
        # THINKME: Do we need an ARCHIVAL_OBJECT_FACETS separate to RESOURCE_FACETS here?
        @search_data = Search.for_type(session[:repo_id], ["archival_object"], params_for_backend_search.merge({"facet[]" => SearchResultData.RESOURCE_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => []})
        search_params["type[]"] = ["archival_object"]
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), 'items.' )
      }
    end
  end


end
