# frozen_string_literal: true

module API
  class ManagedLicenses < ::API::Base
    include PaginationParams

    feature_category :security_policy_management
    urgency :low

    before { authenticate! unless route.settings[:skip_authentication] }

    helpers do
      def authorize_can_read!
        authorize!(:read_software_license_policy, user_project)
      end

      def authorize_can_admin!
        authorize!(:admin_software_license_policy, user_project)
      end

      def deprecation_message
        docs_page = Rails.application.routes.url_helpers.help_page_url('ee/user/compliance/license_approval_policies')

        'License-Check feature and Managed License API endpoint were removed. ' \
          'Users who wish to continue to enforce approvals based on detected licenses are encouraged ' \
          'to use the Scan Result Policies feature instead. ' \
          "See #{docs_page}"
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get project software license policies' do
        success code: 200, model: EE::API::Entities::ManagedLicense
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
      end
      route_setting :skip_authentication, true
      params do
        use :pagination
      end
      get ':id/managed_licenses' do
        authorize_can_read!

        present []
      end

      desc 'Get a specific software license policy from a project' do
        success code: 200, model: EE::API::Entities::ManagedLicense
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
      end
      get ':id/managed_licenses/:managed_license_id', requirements: { managed_license_id: /.*/ } do
        authorize_can_read!

        present []
      end

      desc 'Create a new software license policy in a project' do
        success code: 201, model: EE::API::Entities::ManagedLicense
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :name, type: String, desc: 'The name of the license', documentation: { example: 'MIT' }
        requires :approval_status,
          type: String,
          values: -> { ::SoftwareLicensePolicy.approval_status_values },
          desc: 'The approval status of the license. "allowed" or "denied".',
          documentation: { example: 'allowed' }
      end
      post ':id/managed_licenses' do
        authorize_can_admin!

        bad_request!(deprecation_message)
      end

      desc 'Update an existing software license policy from a project' do
        success code: 200, model: EE::API::Entities::ManagedLicense
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        optional :name, type: String, desc: 'The name of the license', documentation: { example: 'MIT' }
        optional :approval_status,
          type: String,
          values: -> { ::SoftwareLicensePolicy.approval_status_values },
          desc: 'The approval status of the license. "allowed" or "denied".',
          documentation: { example: 'allowed' }
      end
      patch ':id/managed_licenses/:managed_license_id', requirements: { managed_license_id: /.*/ } do
        authorize_can_admin!

        bad_request!(deprecation_message)
      end

      desc 'Delete an existing software license policy from a project' do
        success code: 204
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
      end
      delete ':id/managed_licenses/:managed_license_id', requirements: { managed_license_id: /.*/ } do
        authorize_can_admin!

        bad_request!(deprecation_message)
      end
    end
  end
end
