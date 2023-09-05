# frozen_string_literal: true

module QA
  module EE
    module Resource
      class ExternalAuditEventDestination < QA::Resource::Base
        include QA::Resource::GraphQL

        attributes :id,
          :destination_url,
          :verification_token,
          :name

        attribute :group do
          QA::Resource::Group.fabricate_via_api! do |group|
            group.path = "audit-event-streaming-#{Faker::Alphanumeric.alphanumeric(number: 8)}"
          end
        end

        def fabricate_via_api!
          api_get
        rescue ResourceNotFoundError
          api_post
        end

        def gid
          "gid://gitlab/AuditEvents::ExternalAuditEventDestination/#{id}"
        end

        # Get Audit Event Destination
        #
        # @return [Hash]
        def api_get
          resource = all(group: group)
            .fetch(:nodes, [])
            .find { |node| node[:destination_url] == destination_url }
          raise ResourceNotFoundError if resource.nil?

          resource[:id] = resource.fetch(:id).split('/').last if resource.key?(:id)
          process_api_response(resource)
        end

        # All audit event destinations
        #
        # @param [Hash] kwargs arguments to be used to query the API to search for resources with a specific criteria
        # @return [Array]
        def all(group:)
          process_api_response(
            api_post_to(
              api_get_path,
              <<~GQL
                query {
                  group(fullPath: "#{group.full_path}") {
                    id
                    externalAuditEventDestinations {
                      nodes {
                        destinationUrl
                        verificationToken
                        id
                        name
                        headers {
                          nodes {
                            key
                            value
                            id
                          }
                        }
                        eventTypeFilters
                      }
                    }
                  }
                }
              GQL
            )
          )
        end

        # Graphql mutation to create an Audit Event Destination
        #
        # @return [String]
        def api_post_body
          <<~GQL
            mutation {
              externalAuditEventDestinationCreate(input: { #{mutation_params} }) {
                errors
                externalAuditEventDestination {
                  id
                  destinationUrl
                  verificationToken
                  name
                  group {
                    name
                  }
                }
              }
            }
          GQL
        end

        # Graphql mutation to delete an Audit Event Destination
        #
        # @return [String]
        def api_delete_body
          <<~GQL
            mutation {
              externalAuditEventDestinationDestroy(input: { id: "#{gid}" }) {
                errors
              }
            }
          GQL
        end

        # Graphql mutation to add event type filters
        #
        # @return [Hash]
        def add_filters(filters)
          mutation = <<~GQL
            mutation {
              auditEventsStreamingDestinationEventsAdd(input: {
                destinationId: "#{gid}",
                eventTypeFilters: ["#{filters.join('","')}"]
              }) {
                errors
                eventTypeFilters
              }
            }
          GQL
          api_post_to(api_get_path, mutation)
        end

        # Graphql mutation to add custom headers to the streamed events
        #
        # @return [void]
        def add_headers(headers)
          headers.each do |k, v|
            mutation = <<~GQL
              mutation {
                auditEventsStreamingHeadersCreate(input: { destinationId: "#{gid}", key: "#{k}", value: "#{v}" }) {
                  errors
                }
              }
            GQL
            api_post_to(api_get_path, mutation)
          end
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
          params = %(destinationUrl: "#{destination_url}", name: "#{name}", groupPath: "#{group.full_path}")

          if defined?(@verification_token) && @verification_token.present?
            params += %(, verificationToken: "#{@verification_token}")
          end

          params
        end

        # Standardize keys as snake case
        #
        # @return [Hash]
        def transform_api_resource(api_resource)
          api_resource.deep_transform_keys { |key| key.to_s.underscore.to_sym }
        end
      end
    end
  end
end
