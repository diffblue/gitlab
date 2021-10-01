# frozen_string_literal: true

module API
  class License < ::API::Base
    before { authenticated_as_admin! }

    feature_category :license

    resource :license do
      desc 'Get information on the currently active license' do
        success EE::API::Entities::GitlabLicenseWithActiveUsers
      end
      get do
        license = ::License.current

        present license, with: EE::API::Entities::GitlabLicenseWithActiveUsers
      end

      desc 'Add a new license' do
        success EE::API::Entities::GitlabLicenseWithActiveUsers
      end
      params do
        requires :license, type: String, desc: 'The license text'
      end
      post do
        license = ::License.new(data: params[:license])
        if license.save
          present license, with: EE::API::Entities::GitlabLicenseWithActiveUsers
        else
          render_api_error!(license.errors.full_messages.first, 400)
        end
      end

      desc 'Delete a license'
      params do
        requires :id, type: Integer, desc: 'The license id'
      end
      delete ':id' do
        license = LicensesFinder.new(current_user, id: params[:id]).execute.first

        Licenses::DestroyService.new(license, current_user).execute

        no_content!
      end
    end

    resource :licenses do
      desc 'Get a list of licenses' do
        success EE::API::Entities::GitlabLicense
      end
      get do
        licenses = LicensesFinder.new(current_user).execute

        present licenses, with: EE::API::Entities::GitlabLicense, current_active_users_count: ::License.current&.daily_billable_users_count
      end
    end
  end
end
