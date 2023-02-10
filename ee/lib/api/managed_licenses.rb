# frozen_string_literal: true

module API
  class ManagedLicenses < ::API::Base
    include PaginationParams

    feature_category :security_policy_management
    urgency :low

    before { authenticate! unless route.settings[:skip_authentication] }

    helpers do
      # Make the software license policy specified by id in the request available
      def software_license_policy
        id = params[:managed_license_id]
        @software_license_policy ||=
          SoftwareLicensePoliciesFinder.new(current_user, user_project, name_or_id: id).find
      end

      def authorize_can_read!
        authorize!(:read_software_license_policy, user_project)
      end

      def authorize_can_admin!
        authorize!(:admin_software_license_policy, user_project)
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

        software_license_policies = user_project.software_license_policies.without_scan_result_policy_read
        present paginate(software_license_policies), with: EE::API::Entities::ManagedLicense
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
        break not_found!('SoftwareLicensePolicy') unless software_license_policy

        present software_license_policy, with: EE::API::Entities::ManagedLicense
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

        result = SoftwareLicensePolicies::CreateService.new(
          user_project,
          current_user,
          declared_params(include_missing: false)
        ).execute
        created_software_license_policy = result[:software_license_policy]

        if result[:status] == :success
          present created_software_license_policy, with: EE::API::Entities::ManagedLicense
        else
          render_api_error!(result[:message], result[:http_status])
        end
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
        break not_found!('SoftwareLicensePolicy') unless software_license_policy

        result = SoftwareLicensePolicies::UpdateService.new(
          user_project,
          current_user,
          declared_params(include_missing: false).except(:id, :name)
        ).execute(@software_license_policy)

        if result[:status] == :success
          present @software_license_policy, with: EE::API::Entities::ManagedLicense
        else
          render_api_error!(result[:message], result[:http_status])
        end
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
        not_found!('SoftwareLicensePolicy') unless software_license_policy

        SoftwareLicensePolicies::DeleteService
          .new(user_project, current_user)
          .execute(software_license_policy)

        no_content!
      end
    end
  end
end
