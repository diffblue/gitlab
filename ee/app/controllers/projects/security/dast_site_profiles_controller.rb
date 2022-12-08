# frozen_string_literal: true

module Projects
  module Security
    class DastSiteProfilesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions
      include API::Helpers::GraphqlHelpers

      before_action do
        authorize_read_on_demand_dast_scan!
      end

      feature_category :dynamic_application_security_testing
      urgency :low

      def new
      end

      def edit
        global_id = Gitlab::GlobalId.as_global_id(params[:id], model_name: 'DastSiteProfile')

        query = %(
          {
            project(fullPath: "#{project.full_path}") {
              dastSiteProfile(id: "#{global_id}") {
                id
                name: profileName
                targetUrl
                targetType
                excludedUrls
                requestHeaders
                auth { enabled url username usernameField password passwordField submitField }
                referencedInSecurityPolicies
                scanMethod
              }
            }
          }
        )

        @site_profile = run_graphql!(
          query: query,
          context: { current_user: current_user },
          transform: -> (result) { result.dig('data', 'project', 'dastSiteProfile') }
        )

        return render_404 unless @site_profile
      end
    end
  end
end
