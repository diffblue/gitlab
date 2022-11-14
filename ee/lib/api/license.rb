# frozen_string_literal: true

module API
  class License < ::API::Base
    before { authenticated_as_admin! }

    LICENSES_TAGS = %w[licenses].freeze

    feature_category :sm_provisioning
    urgency :low

    resource :license do
      desc 'Retrieve information about the current license' do
        detail 'Get information on the currently active license'
        success EE::API::Entities::GitlabLicenseWithActiveUsers
        tags LICENSES_TAGS
      end
      get do
        license = ::License.current

        present license, with: EE::API::Entities::GitlabLicenseWithActiveUsers
      end

      desc 'Add a new license' do
        detail 'Adds a new licence'
        success EE::API::Entities::GitlabLicenseWithActiveUsers
        failure [
          { code: 400, message: 'Bad request' }
        ]
        tags LICENSES_TAGS
      end
      params do
        requires :license, type: String, desc: 'The license string'
      end
      post do
        license = ::License.new(data: params[:license])
        if license.save
          present license, with: EE::API::Entities::GitlabLicenseWithActiveUsers
        else
          render_api_error!(license.errors.full_messages.first, 400)
        end
      end

      desc 'Delete a license' do
        detail 'Deletes a license'
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags LICENSES_TAGS
      end
      params do
        requires :id, type: Integer, desc: 'ID of the GitLab license'
      end
      delete ':id' do
        license = LicensesFinder.new(current_user, id: params[:id]).execute.first

        Licenses::DestroyService.new(license, current_user).execute

        no_content!
      end
    end

    resource :licenses do
      desc 'Retrieve information about all licenses' do
        detail 'Get a list of licenses'
        success EE::API::Entities::GitlabLicense
        failure [
          { code: 403, message: 'Forbidden' }
        ]
        is_array true
        tags LICENSES_TAGS
      end
      get do
        licenses = LicensesFinder.new(current_user).execute

        present licenses, with: EE::API::Entities::GitlabLicense, current_active_users_count: ::License.current&.daily_billable_users_count
      end
    end
  end
end
