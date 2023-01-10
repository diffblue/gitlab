# frozen_string_literal: true

module API
  module Scim
    class InstanceScim < ::API::Base
      feature_category :authentication_and_authorization

      prefix 'api/scim'
      version 'v2'
      content_type :json, 'application/scim+json'
      USER_ID_REQUIREMENTS = { id: /.+/ }.freeze

      helpers ::EE::API::Helpers::ScimPagination

      helpers do
        def check_access!
          token = Doorkeeper::OAuth::Token.from_request(
            current_request,
            *Doorkeeper.configuration.access_token_methods
          )
          unauthorized! unless token && ScimOauthAccessToken.token_matches?(token)
        end

        def render_scim_error(error_class, message)
          error!({ with: error_class }.merge(detail: message), error_class::STATUS)
        end

        def scim_not_found!(message:)
          render_scim_error(::EE::API::Entities::Scim::NotFound, message)
        end

        def scim_error!(message:)
          render_scim_error(::EE::API::Entities::Scim::Error, message)
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
        end
      end
    end
  end
end
