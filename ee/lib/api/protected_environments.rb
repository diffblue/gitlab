# frozen_string_literal: true

module API
  class ProtectedEnvironments < ::API::Base
    include PaginationParams

    project_protected_environments_tags = %w[project_protected_environments]
    group_protected_environments_tags = %w[group_protected_environments]

    ENVIRONMENT_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(name: API::NO_SLASH_URL_PART_REGEX)

    feature_category :continuous_delivery
    urgency :low

    helpers do
      params :shared_params do
        optional :user_id, type: Integer, desc: 'The ID of a user with access to the project'
        optional :group_id, type: Integer, desc: 'The ID of a group with access to the project'
        optional :group_inheritance_type,
          type: Integer,
          values: ::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE.values,
          desc: 'Specify whether to take inherited group membership into account. Use `0` for direct ' \
                'group membership or `1` for all inherited groups. Default is `0`'
      end

      params :shared_update_params do
        optional :id, type: Integer, desc: 'The ID of the approval rule to update'
        optional :_destroy, type: Boolean, desc: 'Deletes the object when true'
      end

      params :deploy_access_levels do
        requires :deploy_access_levels,
          as: :deploy_access_levels_attributes,
          type: Array,
          desc: 'Array of access levels allowed to deploy, with each described by a hash. One of ' \
                '`user_id`, `group_id` or `access_level`. They take the form of `{user_id: integer}`, ' \
                '`{group_id: integer}` or `{access_level: integer}` respectively.' do
          use :shared_params

          optional :access_level,
            type: Integer,
            values: ::ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS,
            desc: 'The access levels allowed to deploy'
        end
      end

      params :optional_approval_rules do
        optional :approval_rules,
          as: :approval_rules_attributes,
          type: Array,
          desc: 'Array of access levels allowed to approve, with each described by a hash. One of ' \
                '`user_id`, `group_id` or `access_level`. They take the form of `{user_id: integer}`, ' \
                '`{group_id: integer}` or `{access_level: integer}` respectively. You can also specify the ' \
                'number of required approvals from the specified entity with `required_approvals` field.' do
          use :shared_params
          use :shared_update_params

          optional :access_level,
            type: Integer,
            values: ::ProtectedEnvironments::ApprovalRule::ALLOWED_ACCESS_LEVELS,
            desc: 'The access levels allowed to approve'

          optional :required_approvals,
            type: Integer,
            default: 1,
            desc: 'The number of approvals required for this rule'

          at_least_one_of :access_level, :user_id, :group_id
        end
      end

      params :optional_deploy_access_levels do
        optional :deploy_access_levels, as: :deploy_access_levels_attributes, type: Array, desc: 'An array of users/groups allowed to deploy environment' do
          use :shared_params
          use :shared_update_params

          optional :access_level,
            type: Integer,
            values: ::ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS,
            desc: 'The access levels allowed to deploy'
        end
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        def protected_environment
          @protected_environment ||= user_project.protected_environments.find_by_name!(params[:name])
        end
      end

      before { authorize_admin_project }

      desc 'List protected environments' do
        detail 'Gets a list of protected environments from a project. This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '404', message: 'Not found' }
        ]
        is_array true
        tags project_protected_environments_tags
      end
      params do
        use :pagination
      end
      get ':id/protected_environments' do
        protected_environments = user_project.protected_environments.sorted_by_name

        present paginate(protected_environments), with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end

      desc 'Get a single protected environment' do
        detail 'Gets a single protected environment. This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '404', message: 'Not found' }
        ]
        tags project_protected_environments_tags
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
      end
      get ':id/protected_environments/:name', requirements: ENVIRONMENT_ENDPOINT_REQUIREMENTS do
        present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end

      desc 'Protect a single environment' do
        detail 'Protects a single environment. This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '409', message: 'Conflict' },
          { code: '404', message: 'Not found' },
          { code: '422', message: 'Unprocessable entity' }
        ]
        tags project_protected_environments_tags
      end
      params do
        requires :name, type: String, desc: 'The name of the environment'
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

      desc 'Update a protected environment' do
        detail 'Updates a single environment. This feature was introduced in GitLab 15.4'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '404', message: 'Not found' },
          { code: '422', message: 'Unprocessable entity' }
        ]
        tags project_protected_environments_tags
      end
      params do
        requires :name, type: String, desc: 'The name of the environment'
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
        detail 'Unprotects the given protected environment. This feature was introduced in GitLab 12.8.'
        tags project_protected_environments_tags
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
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group maintained by the authenticated user'
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

      desc 'List group-level protected environments' do
        detail 'Gets a list of protected environments from a group. This feature was introduced in GitLab 14.0.'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '404', message: 'Not found' }
        ]
        is_array true
        tags group_protected_environments_tags
      end
      params do
        use :pagination
      end
      get ':id/protected_environments' do
        protected_environments = user_group.protected_environments.sorted_by_name

        present paginate(protected_environments), with: ::EE::API::Entities::ProtectedEnvironment
      end

      desc 'Get a single protected environment' do
        detail 'Gets a single protected environment. This feature was introduced in GitLab 14.0.'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '404', message: 'Not found' }
        ]
        tags group_protected_environments_tags
      end
      params do
        requires :name,
          type: String,
          desc: 'The deployment tier of the protected environment. ' \
                'One of `production`, `staging`, `testing`, `development`, or `other`'
      end
      get ':id/protected_environments/:name' do
        present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment
      end

      desc 'Protect a single environment' do
        detail 'Protects a single environment. This feature was introduced in GitLab 14.0.'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '409', message: 'Conflict' },
          { code: '404', message: 'Not found' },
          { code: '422', message: 'Unprocessable entity' }
        ]
        tags group_protected_environments_tags
      end
      params do
        requires :name,
          type: String,
          desc: 'The deployment tier of the protected environment. ' \
                'One of `production`, `staging`, `testing`, `development`, or `other`'

        optional :required_approval_count,
          type: Integer,
          desc: 'The number of approvals required to deploy to this environment',
          default: 0

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

      desc 'Update a protected environment' do
        detail 'Updates a single environment. This feature was introduced in GitLab 15.4.'
        success ::EE::API::Entities::ProtectedEnvironment
        failure [
          { code: '404', example: 'Not found' },
          { code: '422', example: 'Unprocessable entity' }
        ]
        tags group_protected_environments_tags
      end
      params do
        requires :name,
          type: String,
          desc: 'The deployment tier of the protected environment. ' \
                'One of production, staging, testing, development, or other'

        optional :required_approval_count,
          type: Integer,
          desc: 'The number of approvals required to deploy to this environment',
          default: 0

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
        tags group_protected_environments_tags
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
