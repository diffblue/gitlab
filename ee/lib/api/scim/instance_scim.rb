# frozen_string_literal: true

module API
  module Scim
    class InstanceScim < ::API::Base
      feature_category :system_access

      prefix 'api/scim'
      version 'v2'
      content_type :json, 'application/scim+json'
      USER_ID_REQUIREMENTS = { id: /.+/ }.freeze

      helpers ::EE::API::Helpers::ScimPagination
      helpers ::API::Helpers::ScimHelpers

      helpers do
        def check_access!
          token = Doorkeeper::OAuth::Token.from_request(
            current_request,
            *Doorkeeper.configuration.access_token_methods
          )
          unauthorized! unless token && ScimOauthAccessToken.token_matches_for_instance?(token)
        end

        def find_user_identity(extern_uid)
          ScimIdentity.for_instance.with_extern_uid(extern_uid).first
        end

        def patch_deprovision(identity)
          ::EE::Gitlab::Scim::DeprovisioningService.new(identity).execute

          true
        rescue StandardError => e
          logger.error(
            identity: identity,
            error: e.class.name,
            message: e.message,
            source: "#{__FILE__}:#{__LINE__}"
          )
          scim_error!(message: e.message)
        end

        def reprovision(identity)
          ::EE::Gitlab::Scim::ReprovisioningService.new(identity).execute

          true
        rescue StandardError => e
          logger.error(
            identity: identity,
            error: e.class.name,
            message: e.message,
            source: "#{__FILE__}:#{__LINE__}"
          )
          scim_error!(message: e.message)
        end
      end

      namespace 'application' do
        resource :Users do
          before do
            not_found! if Gitlab.com?
            check_instance_saml_configured
            not_found! unless ::License.feature_available?(:instance_level_scim)
          end

          desc 'Get SCIM users' do
            success ::EE::API::Entities::Scim::Users
          end

          get do
            check_access!
            results = ScimFinder.new.search(params)
            response_page = scim_paginate(results)

            status :ok
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
            success ::EE::API::Entities::Scim::Users
          end

          get ':id', requirements: USER_ID_REQUIREMENTS do
            check_access!
            identity = ScimIdentity.with_extern_uid(params[:id]).first
            scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

            status 200

            present identity, with: ::EE::API::Entities::Scim::User
          end

          desc 'Create a SCIM user' do
            success ::EE::API::Entities::Scim::Users
          end

          post do
            check_access!
            parser = ::EE::Gitlab::Scim::ParamsParser.new(params)
            result = ::EE::Gitlab::Scim::ProvisioningService.new(parser.post_params).execute

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

          desc 'Updates a SCIM user'

          patch ':id', requirements: USER_ID_REQUIREMENTS do
            check_access!
            identity = find_user_identity(params[:id])
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

          desc 'Removes a SCIM user'

          delete ':id', requirements: USER_ID_REQUIREMENTS do
            check_access!
            identity = find_user_identity(params[:id])
            scim_not_found!(message: "Resource #{params[:id]} not found") unless identity
            patch_deprovision(identity)
            no_content!
          end
        end
      end
    end
  end
end
