# frozen_string_literal: true

module API
  class ProtectedEnvironments < ::API::Base
    include PaginationParams

    ENVIRONMENT_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(name: API::NO_SLASH_URL_PART_REGEX)

    feature_category :continuous_delivery
    urgency :low

    helpers do
      params :shared_params do
        optional :user_id, type: Integer
        optional :group_id, type: Integer
        optional :group_inheritance_type, type: Integer, values: ::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE.values
      end

      params :shared_update_params do
        optional :id, type: Integer
        optional :_destroy, type: Boolean, desc: 'Delete the object when true'
      end

      params :deploy_access_levels do
        requires :deploy_access_levels, as: :deploy_access_levels_attributes, type: Array, desc: 'An array of users/groups allowed to deploy environment' do
          use :shared_params

          optional :access_level, type: Integer, values: ::ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS
        end
      end

      params :optional_approval_rules do
        optional :approval_rules, as: :approval_rules_attributes, type: Array, desc: 'An array of users/groups allowed to approve/reject a deployment' do
          use :shared_params
          use :shared_update_params

          optional :access_level, type: Integer, values: ::ProtectedEnvironments::ApprovalRule::ALLOWED_ACCESS_LEVELS
          optional :required_approvals, type: Integer, default: 1, desc: 'The number of approvals required in this rule'

          at_least_one_of :access_level, :user_id, :group_id
        end
      end

      params :optional_deploy_access_levels do
        optional :deploy_access_levels, as: :deploy_access_levels_attributes, type: Array, desc: 'An array of users/groups allowed to deploy environment' do
          use :shared_params
          use :shared_update_params

          optional :access_level, type: Integer, values: ::ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        def protected_environment
          @protected_environment ||= user_project.protected_environments.find_by_name!(params[:name])
        end
      end

      before { authorize_admin_project }

      desc "Get a project's protected environments" do
        detail 'This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        use :pagination
      end
      get ':id/protected_environments' do
        protected_environments = user_project.protected_environments.sorted_by_name

        present paginate(protected_environments), with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end

      desc 'Get a single protected environment' do
        detail 'This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
      end
      get ':id/protected_environments/:name', requirements: ENVIRONMENT_ENDPOINT_REQUIREMENTS do
        present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end

      desc 'Protect a single environment' do
        detail 'This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
        optional :required_approval_count, type: Integer, desc: 'The number of approvals required to deploy to this environment', default: 0

        use :deploy_access_levels
        use :optional_approval_rules
      end
      post ':id/protected_environments' do
        protected_environment = user_project.protected_environments.find_by_name(params[:name])

        if protected_environment
          conflict!("Protected environment '#{params[:name]}' already exists")
        end

        declared_params = declared_params(include_missing: false)
        protected_environment = ::ProtectedEnvironments::CreateService
                                  .new(container: user_project, current_user: current_user, params: declared_params).execute

        if protected_environment.persisted?
          present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
        else
          render_api_error!(protected_environment.errors.full_messages, 422)
        end
      end

      desc 'Update a single environment' do
        detail 'This feature was introduced in GitLab 15.4'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
        optional :required_approval_count, type: Integer, desc: 'The number of approvals required to deploy to this environment'

        use :optional_deploy_access_levels
        use :optional_approval_rules
      end
      put ':id/protected_environments/:name' do
        not_found! unless protected_environment

        declared_params = declared_params(include_missing: false)

        result = ::ProtectedEnvironments::UpdateService
                   .new(container: user_project, current_user: current_user, params: declared_params)
                   .execute(protected_environment)

        if result
          present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
        else
          render_api_error!(protected_environment.errors.full_messages, 422)
        end
      end

      desc 'Unprotect a single environment' do
        detail 'This feature was introduced in GitLab 12.8.'
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
      end
      delete ':id/protected_environments/:name', requirements: ENVIRONMENT_ENDPOINT_REQUIREMENTS do
        destroy_conditionally!(protected_environment) do
          ::ProtectedEnvironments::DestroyService.new(container: user_project, current_user: current_user).execute(protected_environment)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of the group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        def protected_environment
          @protected_environment ||= user_group.protected_environments.find_by_name!(params[:name])
        end
      end

      before do
        authorize! :admin_protected_environment, user_group
      end

      desc "Get a group's protected environments" do
        detail 'This feature was introduced in GitLab 14.0.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        use :pagination
      end
      get ':id/protected_environments' do
        protected_environments = user_group.protected_environments.sorted_by_name

        present paginate(protected_environments), with: ::EE::API::Entities::ProtectedEnvironment
      end

      desc 'Get a single protected environment' do
        detail 'This feature was introduced in GitLab 14.0.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The tier name of the protected environment'
      end
      get ':id/protected_environments/:name' do
        present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment
      end

      desc 'Protect a single environment' do
        detail 'This feature was introduced in GitLab 14.0.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The tier name of the protected environment'
        optional :required_approval_count, type: Integer, desc: 'The number of approvals required to deploy to this environment', default: 0

        use :deploy_access_levels
        use :optional_approval_rules
      end
      post ':id/protected_environments' do
        protected_environment = user_group.protected_environments.find_by_name(params[:name])

        if protected_environment
          conflict!("Protected environment '#{params[:name]}' already exists")
        end

        declared_params = declared_params(include_missing: false)
        protected_environment = ::ProtectedEnvironments::CreateService
                                  .new(container: user_group, current_user: current_user, params: declared_params).execute

        if protected_environment.persisted?
          present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment
        else
          render_api_error!(protected_environment.errors.full_messages, 422)
        end
      end

      desc 'Update a single environment' do
        detail 'This feature was introduced in GitLab 15.4'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
        optional :required_approval_count, type: Integer, desc: 'The number of approvals required to deploy to this environment', default: 0

        use :optional_deploy_access_levels
        use :optional_approval_rules
      end
      put ':id/protected_environments/:name' do
        not_found! unless protected_environment

        declared_params = declared_params(include_missing: false)

        result = ::ProtectedEnvironments::UpdateService
                   .new(container: user_group, current_user: current_user, params: declared_params)
                   .execute(protected_environment)

        if result
          present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_group
        else
          render_api_error!(protected_environment.errors.full_messages, 422)
        end
      end

      desc 'Unprotect a single environment' do
        detail 'This feature was introduced in GitLab 14.0.'
      end
      params do
        requires :name, type: String, desc: 'The tier name of the protected environment'
      end
      delete ':id/protected_environments/:name' do
        destroy_conditionally!(protected_environment) do
          ::ProtectedEnvironments::DestroyService.new(container: user_group, current_user: current_user).execute(protected_environment)
        end
      end
    end
  end
end
