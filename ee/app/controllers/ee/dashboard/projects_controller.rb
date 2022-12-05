# frozen_string_literal: true

module EE
  module Dashboard
    module ProjectsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :check_adjourned_deletion_listing_availability, only: [:removed]

        urgency :low, [:removed]
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def removed
        @projects = load_projects(params.merge(projects_pending_deletion_params))

        respond_to do |format|
          format.html
          format.json do
            render json: {
              html: view_to_html_string("dashboard/projects/_projects", projects: @projects)
            }
          end
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      private

      override :preload_associations
      def preload_associations(projects)
        super.with_compliance_framework_settings
             .with_group_saml_provider
             .with_project_setting
      end

      def check_adjourned_deletion_listing_availability
        return render_404 unless can?(current_user, :list_removable_projects)
      end

      def projects_pending_deletion_params
        finder_params = { aimed_for_deletion: true, include_hidden: true }

        unless current_user.can_admin_all_resources?
          finder_params[:min_access_level] = ::Gitlab::Access::OWNER

          if ::Gitlab::CurrentSettings.should_check_namespace_plan?
            finder_params[:feature_available] = :adjourned_deletion_for_projects_and_groups
          end
        end

        finder_params
      end
    end
  end
end
