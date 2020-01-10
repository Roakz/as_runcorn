class ChargeableServicesController < ApplicationController

  RESOLVES = ['service_items']

  set_access_control  "administer_system" => [:create],
                      "update_charges" => [:edit, :update],
                      "view_repository" => [:index, :show]

  def index
    ids = JSONModel::HTTP.get_json('/chargeable_services', 'all_ids' => true)
    @list = JSONModel::HTTP.get_json('/chargeable_services',
                                     'id_set' => ids.join(","),
                                     'resolve[]' => RESOLVES)
  end


  def show
    @chargeable_service = JSONModel(:chargeable_service).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end


  def edit
    @chargeable_service = JSONModel(:chargeable_service).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end


  def update
    # wangle the service_items coz the multi-linker sends em back wonky
    # FIXME: surely this is just my stoopid
    hash = params[:chargeable_service].to_hash
    hash['service_items'] = hash['service_items']['ref'].zip(hash['service_items']['_resolved']).map{|ref,res| {'ref' => ref, '_resolved' => res}}
    params[:chargeable_service] = hash

    handle_crud(:instance => :chargeable_service,
                :model => JSONModel(:chargeable_service),
                :obj => JSONModel(:chargeable_service).find(params[:id], find_opts.merge('resolve[]' => RESOLVES)),
                :on_invalid => ->(){
                  render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("chargeable_service._frontend.messages.updated")
                  redirect_to :controller => :chargeable_services, :action => :show, :id => id
                })
  end


  def current_record
    @chargeable_service
  end

end
