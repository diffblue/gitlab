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

        resource ":user_id/personal_access_tokens" do
          helpers do
            def user
              user_group.provisioned_users.find_by_id(params[:user_id])
            end

            def validate_service_account_user
              not_found! unless user
              bad_request!("User is not of type Service Account") unless user.service_account?
            end
          end

          desc 'Create a personal access token. Available only for group owners.' do
            detail 'This feature was introduced in GitLab 16.1'
            success Entities::PersonalAccessTokenWithToken
          end

          params do
            requires :name, type: String, desc: 'The name of the personal access token'
            requires :scopes, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
              values: ::Gitlab::Auth.all_available_scopes.map(&:to_s),
              desc: 'The array of scopes of the personal access token'
            optional :expires_at, type: Date,
              desc: 'The expiration date of the personal access token in ISO 8601 format'
          end

          post do
            validate_service_account_user

            response = ::PersonalAccessTokens::CreateService.new(
              current_user: current_user, target_user: user, params: declared_params.merge(group: user_group)
            ).execute

            if response.success?
              present response.payload[:personal_access_token], with: Entities::PersonalAccessTokenWithToken
            else
              render_api_error!(response.message, response.http_status || :unprocessable_entity)
            end
          end

          desc 'Rotate personal access token' do
            detail 'Rotates a personal access token.'
            success Entities::PersonalAccessTokenWithToken
          end

          post ':token_id/rotate' do
            validate_service_account_user

            token = PersonalAccessToken.find_by_id(params[:token_id])

            if token&.user == user
              response = ::PersonalAccessTokens::RotateService.new(current_user, token).execute

              if response.success?
                status :ok

                new_token = response.payload[:personal_access_token]
                present new_token, with: Entities::PersonalAccessTokenWithToken
              else
                bad_request!(response.message)
              end
            else
              not_found!
            end
          end
        end
      end
    end
  end
end
