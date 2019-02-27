class ManagedRegistrationController < ApplicationController

  set_access_control "approve_agency_registration" => [:approve],
                     "update_agent_record" => [:submit, :withdraw],
                     "view_repository" => [:index]


  def index
    @list = JSONModel::HTTP.get_json("/agents/corporate_entities/registrations/all")
  end


  def submit
    handle_action('submit')
  end


  def withdraw
    handle_action('withdraw')
  end


  def approve
    handle_action('approve')
  end


  def handle_action(action)
    resp = JSONModel::HTTP.post_form("/agents/corporate_entities/#{params[:id]}/#{action}")
     if resp.code === "200"
       flash[:success] = I18n.t("managed_registration.actions.success.#{action}")
     else
       flash[:error] = I18n.t('managed_registration.actions.error', :errors => resp.body)
     end

    redirect_to(:controller => :agents, :action => :show, :agent_type => :agent_corporate_entity,  :id => params[:id])
  end
end
