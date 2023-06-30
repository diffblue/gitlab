# frozen_string_literal: true

module QA
  module EE
    module Resource
      # GraphQL mutations implemented as part of https://gitlab.com/gitlab-org/gitlab/-/issues/335175
      class InstanceAuditEventExternalDestination < QA::Resource::Base
        attributes :id,
          :destination_url,
          :verification_token

        MAX_RETRY_ATTEMPTS = 6
        RETRY_SLEEP_DURATION = 10

        def initialize
          @mutation_retry_attempts = 0
        end

        def fabricate_via_api!
          super
        rescue ResourceFabricationFailedError => e
          # Until the feature flag is removed (see https://gitlab.com/gitlab-org/gitlab/-/issues/393772), toggling the
          # flag could lead to flakiness if the flag state is cached. So we retry the creation and fail if we don't
          # succeed after a minute
          raise unless e.message.include?('You do not have access to this mutation') ||
            e.message.include?('Requests to localhost are not allowed')

          raise if @mutation_retry_attempts >= MAX_RETRY_ATTEMPTS

          @mutation_retry_attempts += 1
          sleep RETRY_SLEEP_DURATION
          retry
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def gid
          "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/#{id}"
        end

        # The path to get an Instance Audit Event Destination via the GraphQL API
        #
        # @return [String]
        def api_get_path
          "/graphql"
        end

        # The path to create an Instance Audit Event Destination via the GraphQL API (same as the GET path)
        #
        # @return [String]
        def api_post_path
          api_get_path
        end

        # Graphql mutation to create an Instance Audit Event Destination
        #
        # @return [String]
        def api_post_body
          <<~GQL
            mutation {
              instanceExternalAuditEventDestinationCreate(input: { #{mutation_params} }) {
                errors
                instanceExternalAuditEventDestination {
                  id
                  destinationUrl
                  verificationToken
                }
              }
            }
          GQL
        end

        # The path to delete an Instance Audit Event Destination via the GraphQL API (same as the GET path)
        #
        # @return [String]
        def api_delete_path
          api_get_path
        end

        # Graphql mutation to delete an Instance Audit Event Destination
        #
        # @return [String]
        def api_delete_body
          <<~GQL
            mutation {
              instanceExternalAuditEventDestinationDestroy(input: { id: "#{gid}" }) {
                errors
              }
            }
          GQL
        end

        protected

        # Return fields for comparing issues
        #
        # @return [Hash]
        def comparable
          reload! if api_response.nil?

          api_resource
        end

        private

        # Return available parameters formatted to be used in a GraphQL query
        #
        # @return [String]
        def mutation_params
          params = %(destinationUrl: "#{destination_url}")

          if defined?(@verification_token) && @verification_token.present?
            params += %(, verificationToken: "#{@verification_token}")
          end

          params
        end
      end
    end
  end
end
