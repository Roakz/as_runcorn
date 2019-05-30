class ChargeableItemsController < ApplicationController

  RESOLVES = []

  set_access_control  "administer_system" => [:edit, :create, :update],
                      "view_repository" => [:index, :show]

  def index
    @list = JSONModel::HTTP.get_json("/chargeable_items")
  end


  def show
    @chargeable_item = JSONModel(:chargeable_item).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def edit
    @chargeable_item = JSONModel(:chargeable_item).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
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
                  redirect_to :controller => :chargeable_items, :action => :show, :id => id
                })
  end


  def current_record
    @chargeable_item
  end

end
