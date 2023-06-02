# frozen_string_literal: true

module API
  class GroupServiceAccounts < ::API::Base
    feature_category :user_management

    before do
      authenticate!
      authorize! :admin_service_accounts, user_group
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end
    resource 'groups/:id', requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :service_accounts do
        desc 'Create a service account user' do
          detail 'Create a service account user'
          success Entities::UserBasic
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 Group not found' }
          ]
        end
        post do
          response = ::Namespaces::ServiceAccounts::CreateService
                       .new(current_user, { namespace_id: params[:id] }).execute

          if response.status == :success
            present response.payload, with: ::API::Entities::UserSafe, current_user: current_user
          else
            bad_request!(response.message)
          end
        end
      end
    end
  end
end
