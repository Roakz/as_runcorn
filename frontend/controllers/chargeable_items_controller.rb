class ChargeableItemsController < ApplicationController

  RESOLVES = []

  set_access_control  "administer_system" => [:new, :create],
                      "update_charges" => [:edit, :update],
                      "view_repository" => [:index, :show]

  def index
    ids = JSONModel::HTTP.get_json('/chargeable_items', 'all_ids' => true)
    @list = JSONModel::HTTP.get_json('/chargeable_items', 'id_set' => ids.join(","))
  end

  def new
    @chargeable_item = JSONModel(:chargeable_item).new._always_valid!
  end

  def show
    @chargeable_item = JSONModel(:chargeable_item).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def edit
    @chargeable_item = JSONModel(:chargeable_item).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def create
    handle_crud(:instance => :chargeable_item,
                :model => JSONModel(:chargeable_item),
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){
                    flash[:success] = I18n.t("chargeable_item._frontend.messages.created")
                    redirect_to(:controller => :chargeable_items,
                                :action => :edit,
                                :id => id) })
  end

  def update
    handle_crud(:instance => :chargeable_item,
                :model => JSONModel(:chargeable_item),
                :obj => JSONModel(:chargeable_item).find(params[:id], find_opts.merge('resolve[]' => RESOLVES)),
                :on_invalid => ->(){
                  render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("chargeable_item._frontend.messages.updated")
                  redirect_to :controller => :chargeable_items, :action => :edit, :id => id
                })
  end


  def current_record
    @chargeable_item
  end

end
