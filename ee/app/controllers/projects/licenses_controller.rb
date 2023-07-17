# frozen_string_literal: true

module Projects
  class LicensesController < Projects::ApplicationController
    include SecurityAndCompliancePermissions

    before_action :authorize_read_licenses!, only: [:index]
    before_action :authorize_admin_software_license_policy!, only: [:create, :update]

    feature_category :dependency_management
    urgency :low

    def index
      respond_to do |format|
        format.html do
          @licenses_app_data = licenses_app_data
          render status: :ok
        end
        format.json do
          ::Gitlab::UsageDataCounters::LicensesList.count(:views)

          license_compliance = project.license_compliance
          render json: serializer.represent(
            pageable(matching_policies_from(license_compliance)),
            build: license_compliance.latest_build_for_default_branch,
            project: project
          )
        end
      end
    end

    private

    def serializer
      ::LicensesListSerializer.new(project: project, user: current_user)
          .with_pagination(request, response)
    end

    def pageable(items)
      ::Gitlab::ItemsCollection.new(items)
    end

    def matching_policies_params
      params.permit(:detected, :sort_by, :sort_direction, classification: [])
    end

    def matching_policies_from(license_compliance)
      filters = matching_policies_params
      license_compliance.find_policies(
        detected_only: truthy?(filters[:detected]),
        classification: filters[:classification],
        sort: { by: filters[:sort_by], direction: filters[:sort_direction] }
      )
    end

    def truthy?(value)
      value.in?(%w[true 1])
    end

    def write_license_policies_endpoint
      if can?(current_user, :admin_software_license_policy, @project)
        expose_path(api_v4_projects_managed_licenses_path(id: @project.id))
      else
        ''
      end
    end

    def licenses_app_data
      {
        project_licenses_endpoint: project_licenses_path(@project, detected: true, format: :json),
        read_license_policies_endpoint: expose_path(api_v4_projects_managed_licenses_path(id: @project.id)),
        write_license_policies_endpoint: write_license_policies_endpoint,
        documentation_path: help_page_path('user/compliance/license_compliance/index'),
        empty_state_svg_path: helpers.image_path('illustrations/Dependency-list-empty-state.svg'),
        software_licenses: SoftwareLicense.unclassified_licenses_for(project).pluck_names,
        project_id: @project.id,
        project_path: expose_path(api_v4_projects_path(id: @project.id)),
        rules_path: expose_path(api_v4_projects_approval_settings_rules_path(id: @project.id)),
        settings_path: expose_path(api_v4_projects_approval_settings_path(id: @project.id)),
        approvals_documentation_path: help_page_path('user/compliance/license_compliance/index', anchor: 'enabling-license-approvals-within-a-project'),
        locked_approvals_rule_name: ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT
      }
    end
  end
end
