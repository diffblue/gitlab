# frozen_string_literal: true

module API
  module Scim
    class GroupScim < ::API::Base
      include ::Gitlab::Utils::StrongMemoize

      feature_category :system_access

      prefix 'api/scim'
      version 'v2'
      content_type :json, 'application/scim+json'
      USER_ID_REQUIREMENTS = { id: /.+/ }.freeze

      namespace 'groups/:group' do
        params do
          requires :group, type: String
        end

        helpers ::EE::API::Helpers::ScimPagination
        helpers ::API::Helpers::ScimHelpers

        helpers do
          def logger
            API.logger
          end

          def check_access_to_group!(group)
            token = Doorkeeper::OAuth::Token.from_request(
              current_request,
              *Doorkeeper.configuration.access_token_methods
            )
            unauthorized! unless token && ScimOauthAccessToken.token_matches_for_group?(token, group)
          end

          # Instance variable `@group` is necessary for the
          # Gitlab::ApplicationContext in API::API
          def find_and_authenticate_group!(group_path)
            @group = find_group(group_path)

            scim_not_found!(message: "Group #{group_path} not found") unless @group

            unless @group.saml_provider
              scim_not_found!(message: "Group #{group_path} does not have SAML SSO configured")
            end

            check_access_to_group!(@group)

            @group
          end

          def find_user_identity(group, extern_uid)
            return unless group.saml_provider

            group.scim_identities.with_extern_uid(extern_uid).first
          end

          # delete_deprovision handles the response and returns either
          # no_content! or a detailed error message.
          def delete_deprovision(identity)
            service = ::EE::Gitlab::Scim::Group::DeprovisioningService.new(identity).execute

            if service.success?
              no_content!
            else
              logger.error(
                identity: identity,
                error: service.class.name,
                message: service.message,
                source: "#{__FILE__}:#{__LINE__}"
              )
              scim_error!(message: service.message)
            end
          end

          # The method that calls patch_deprovision, update_scim_user, expects a
          # truthy/falsey value, and then continues to handle the request.
          def patch_deprovision(identity)
            service = ::EE::Gitlab::Scim::Group::DeprovisioningService.new(identity).execute

            if service.success?
              true
            else
              logger.error(
                identity: identity,
                error: service.class.name,
                message: service.message,
                source: "#{__FILE__}:#{__LINE__}"
              )
              false
            end
          end

          def reprovision(identity)
            ::EE::Gitlab::Scim::Group::ReprovisioningService.new(identity).execute

            true
          rescue StandardError => e
            logger.error(identity: identity, error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

            false
          end
        end

        resource :Users do
          before do
            check_group_saml_configured
          end

          desc 'Get SCIM users' do
            detail 'This feature was introduced in GitLab 11.10.'
          end
          get do
            group = find_and_authenticate_group!(params[:group])

            results = ScimFinder.new(group).search(params)
            response_page = scim_paginate(results)

            status 200

            result_set = {
              resources: response_page,
              total_results: results.count,
              items_per_page: per_page(params[:count]),
              start_index: params[:startIndex]
            }
            present result_set, with: ::EE::API::Entities::Scim::Users
          rescue ScimFinder::UnsupportedFilter
            scim_error!(message: 'Unsupported Filter')
          end

          desc 'Get a SCIM user' do
            detail 'This feature was introduced in GitLab 11.10.'
          end
          get ':id', requirements: USER_ID_REQUIREMENTS do
            group = find_and_authenticate_group!(params[:group])

            identity = find_user_identity(group, params[:id])

            scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

            status 200

            present identity, with: ::EE::API::Entities::Scim::User
          end

          desc 'Create a SCIM user' do
            detail 'This feature was introduced in GitLab 11.10.'
          end
          post do
            group = find_and_authenticate_group!(params[:group])
            parser = ::EE::Gitlab::Scim::ParamsParser.new(params)
            result = ::EE::Gitlab::Scim::Group::ProvisioningService.new(parser.post_params, group).execute

            case result.status
            when :success
              status 201

              present result.identity, with: ::EE::API::Entities::Scim::User
            when :conflict
              scim_conflict!(
                message: "Error saving user with #{sanitize_request_parameters(params).inspect}: #{result.message}"
              )
            when :error
              scim_error!(
                message: [
                  "Error saving user with #{sanitize_request_parameters(params).inspect}",
                  result.message
                ].compact.join(": ")
              )
            end
          end

          desc 'Updates a SCIM user' do
            detail 'This feature was introduced in GitLab 11.10.'
          end
          patch ':id', requirements: USER_ID_REQUIREMENTS do
            scim_error!(message: 'Missing ID') unless params[:id]

            group = find_and_authenticate_group!(params[:group])
            identity = find_user_identity(group, params[:id])

            scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

            updated = update_scim_user(identity)

            if updated
              no_content!
            else
              scim_error!(
                message: "Error updating #{identity.user.name} with #{sanitize_request_parameters(params).inspect}"
              )
            end
          end

          desc 'Removes a SCIM user' do
            detail 'This feature was introduced in GitLab 11.10.'
          end
          delete ':id', requirements: USER_ID_REQUIREMENTS do
            scim_error!(message: 'Missing ID') unless params[:id]

            group = find_and_authenticate_group!(params[:group])
            identity = find_user_identity(group, params[:id])

            scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

            delete_deprovision(identity)
          end
        end
      end
    end
  end
end
