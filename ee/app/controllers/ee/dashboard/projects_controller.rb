# frozen_string_literal: true

module EE
  module Dashboard
    module ProjectsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :check_adjourned_deletion_listing_availability, only: [:removed]
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def removed
        @projects = load_projects(params.merge(finder_params_for_removed))

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
      end

      override :load_projects
      def load_projects(finder_params)
        @removed_projects_count = ::ProjectsFinder.new(params: finder_params_for_removed, current_user: current_user).execute # rubocop:disable Gitlab/ModuleWithInstanceVariables

        super
      end

      def check_adjourned_deletion_listing_availability
        return render_404 unless License.feature_available?(:adjourned_deletion_for_projects_and_groups)
      end

      def finder_params_for_removed
        finder_params = { aimed_for_deletion: true }

        unless current_user.can_admin_all_resources?
          # only list projects with at least owner access if the user is not an admin
          finder_params[:min_access_level] = ::Gitlab::Access::OWNER
          # only list projects that belongs to a group with premium or above plan
          finder_params[:plans] = (::Plan.paid_plans - [::Plan::BRONZE])
        end

        finder_params
      end
    end
  end
end
