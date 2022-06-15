# frozen_string_literal: true

module Groups
  class ProtectedEnvironmentsController < Groups::ApplicationController
    before_action :authorize_admin_protected_environment!
    before_action :protected_environment, except: [:create]

    feature_category :continuous_delivery

    def create
      protected_environment = ::ProtectedEnvironments::CreateService
        .new(container: @group, current_user: current_user, params: protected_environment_params).execute

      if protected_environment.persisted?
        flash[:notice] = s_('ProtectedEnvironment|Your environment has been protected.')
      else
        flash[:alert] = protected_environment.errors.full_messages.join(', ')
      end

      redirect_to group_settings_ci_cd_path(@group, anchor: 'js-protected-environments-settings')
    end

    def update
      result = ::ProtectedEnvironments::UpdateService
        .new(container: @group, current_user: current_user, params: protected_environment_params)
        .execute(@protected_environment)

      if result
        render json: serialized_protected_environment, status: :ok
      else
        render json: serialized_error_message, status: :unprocessable_entity
      end
    end

    def destroy
      result = ::ProtectedEnvironments::DestroyService
        .new(container: @group, current_user: current_user).execute(@protected_environment)

      if result
        flash[:notice] = s_('ProtectedEnvironment|Your environment has been unprotected')
      else
        flash[:alert] = s_("ProtectedEnvironment|Your environment can't be unprotected")
      end

      redirect_to group_settings_ci_cd_path(@group, anchor: 'js-protected-environments-settings'), status: :found
    end

    private

    def protected_environment
      @protected_environment = @group.protected_environments.find(params[:id])
    end

    def protected_environment_params
      params.require(:protected_environment).permit(
        :name,
        deploy_access_levels_attributes: deploy_access_level_attributes
      )
    end

    def deploy_access_level_attributes
      %i(id _destroy group_id)
    end

    def authorize_admin_protected_environment!
      not_found unless can?(current_user, :admin_protected_environment, group)
    end

    def serialized_protected_environment
      ProtectedEnvironments::Serializer.new.represent(@protected_environment)
    end

    def serialized_error_message
      { errors: @protected_environment.errors.full_messages.to_sentence }
    end
  end
end
