# frozen_string_literal: true
module EE
  module Projects
    module Settings
      module CiCdController
        include ::API::Helpers::RelatedResourcesHelpers
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        prepended do
          before_action :assign_variables_to_gon, only: [:show]
          before_action :define_protected_env_variables, only: [:show]
        end

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        override :show
        def show
          if project.feature_available?(:license_scanning)
            @license_management_url = expose_url(api_v4_projects_managed_licenses_path(id: @project.id))
          end

          super
        end

        override :permitted_project_params
        def permitted_project_params
          super + %i[
            allow_pipeline_trigger_approve_deployment
          ]
        end

        private

        def define_protected_env_variables
          @protected_environments = @project.protected_environments.with_environment_id.sorted_by_name
          @protected_environment = ProtectedEnvironment.new(project: @project)
          # ignoring Layout/LineLength because if we break this into multiple lines, we cause Style/GuardClause errors
          @group_protected_environments = ProtectedEnvironment.for_groups(@project.group.self_and_ancestor_ids) if @project.group # rubocop:disable Layout/LineLength
        end

        def assign_variables_to_gon
          gon.push(current_project_id: project.id)
          gon.push(deploy_access_levels: environment_dropdown.roles_hash)
          gon.push(search_unprotected_environments_url: search_project_protected_environments_path(@project))
        end

        def environment_dropdown
          @environment_dropdown ||= ProtectedEnvironments::EnvironmentDropdownService
        end
      end
    end
  end
end
