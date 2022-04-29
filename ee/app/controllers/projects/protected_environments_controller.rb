# frozen_string_literal: true
class Projects::ProtectedEnvironmentsController < Projects::ApplicationController
  before_action :authorize_admin_project!
  before_action :protected_environment, except: [:create, :search]

  feature_category :continuous_delivery
  urgency :low

  def create
    protected_environment = ::ProtectedEnvironments::CreateService.new(container: @project, current_user: current_user, params: protected_environment_params).execute

    if protected_environment.persisted?
      flash[:notice] = s_('ProtectedEnvironment|Your environment has been protected.')
    else
      flash[:alert] = protected_environment.errors.full_messages.join(', ')
    end

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-protected-environments-settings')
  end

  def update
    result = ::ProtectedEnvironments::UpdateService.new(container: @project, current_user: current_user, params: protected_environment_params).execute(@protected_environment)

    if result
      render json: @protected_environment, status: :ok, include: :deploy_access_levels
    else
      render json: @protected_environment.errors, status: :unprocessable_entity
    end
  end

  def destroy
    result = ::ProtectedEnvironments::DestroyService.new(container: @project, current_user: current_user).execute(@protected_environment)

    if result
      flash[:notice] = s_('ProtectedEnvironment|Your environment has been unprotected')
    else
      flash[:alert] = s_("ProtectedEnvironment|Your environment can't be unprotected")
    end

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-protected-environments-settings'), status: :found
  end

  def search
    unprotected_environment_names = ::ProtectedEnvironments::SearchService.new(container: @project, current_user: current_user).execute(search_params[:query])

    render json: unprotected_environment_names, status: :ok
  end

  private

  def protected_environment
    @protected_environment = @project.protected_environments.find(params[:id])
  end

  def protected_environment_params
    params.require(:protected_environment).permit(
      :name,
      :required_approval_count,
      deploy_access_levels_attributes: deploy_access_level_attributes
    )
  end

  def deploy_access_level_attributes
    %i(access_level id user_id _destroy group_id)
  end

  def search_params
    params.permit(:query)
  end
end
