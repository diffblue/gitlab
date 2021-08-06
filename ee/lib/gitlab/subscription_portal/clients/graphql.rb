# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    module Clients
      module Graphql
        extend ActiveSupport::Concern

        CONNECTIVITY_ERROR = 'CONNECTIVITY_ERROR'

        class_methods do
          def activate(activation_code)
            uuid = Gitlab::CurrentSettings.uuid

            variables = {
              activationCode: activation_code,
              instanceIdentifier: uuid
            }

            query = <<~GQL
              mutation($activationCode: String!, $instanceIdentifier: String!) {
                cloudActivationActivate(
                  input: {
                    activationCode: $activationCode,
                    instanceIdentifier: $instanceIdentifier
                  }
                ) {
                  licenseKey
                  errors
                }
              }
            GQL

            response = execute_graphql_query(
              { query: query, variables: variables }
            )

            return error(CONNECTIVITY_ERROR) unless response[:success]

            response = response.dig(:data, 'data', 'cloudActivationActivate')

            if response['errors'].blank?
              { success: true, license_key: response['licenseKey'] }
            else
              error(response['errors'])
            end
          rescue Gitlab::HTTP::BlockedUrlError, HTTParty::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError, Timeout::Error => e
            Gitlab::ErrorTracking.log_exception(e)
            error(CONNECTIVITY_ERROR)
          end

          def plan_upgrade_offer(namespace_id)
            query = <<~GQL
              {
                subscription(namespaceId: "#{namespace_id}") {
                  eoaStarterBronzeEligible
                  assistedUpgradePlanId
                  freeUpgradePlanId
                }
              }
            GQL

            response = execute_graphql_query({ query: query }).dig(:data)

            if response['errors'].blank?
              eligible = response.dig('data', 'subscription', 'eoaStarterBronzeEligible')
              assisted_upgrade = response.dig('data', 'subscription', 'assistedUpgradePlanId')
              free_upgrade = response.dig('data', 'subscription', 'freeUpgradePlanId')

              {
                success: true,
                eligible_for_free_upgrade: eligible,
                assisted_upgrade_plan_id: assisted_upgrade,
                free_upgrade_plan_id: free_upgrade
              }
            else
              error
            end
          end

          def subscription_last_term(namespace_id)
            return error('Must provide a namespace ID') unless namespace_id

            query = <<~GQL
              query($namespaceId: ID!) {
                subscription(namespaceId: $namespaceId) {
                  lastTerm
                }
              }
            GQL

            response = execute_graphql_query({ query: query, variables: { namespaceId: namespace_id } })

            if response[:success]
              { success: true, last_term: response.dig(:data, 'data', 'subscription', 'lastTerm') }
            else
              error(response.dig(:data, :errors))
            end
          end

          def get_plans(tags:)
            query = <<~GQL
            query getPlans($tags: [PlanTag!]) {
              plans(planTags: $tags) {
                id
              }
            }
            GQL

            response = http_post('graphql', admin_headers, { query: query, variables: { tags: tags } })[:data]

            if response['errors'].blank? && (data = response.dig('data', 'plans'))
              { success: true, data: data }
            else
              track_error(query, response)

              error(response['errors'])
            end
          end

          def filter_purchase_eligible_namespaces(user, namespaces, plan_id: nil, any_self_service_plan: nil)
            query = <<~GQL
            query FilterEligibleNamespaces($customerUid: Int!, $namespaces: [GitlabNamespaceInput!]!, $planId: ID, $eligibleForPurchase: Boolean) {
              namespaceEligibility(customerUid: $customerUid, namespaces: $namespaces, planId: $planId, eligibleForPurchase: $eligibleForPurchase) {
                id
              }
            }
            GQL

            namespace_data = namespaces.map do |namespace|
              {
                id: namespace.id,
                parentId: namespace.parent_id,
                plan: namespace.actual_plan_name,
                trial: !!namespace.trial?,
                kind: namespace.kind,
                membersCountWithDescendants: namespace.group? ? namespace.users_with_descendants.count : nil
              }
            end

            response = http_post(
              'graphql',
              admin_headers,
              { query: query, variables: {
                customerUid: user.id,
                namespaces: namespace_data,
                planId: plan_id,
                eligibleForPurchase: any_self_service_plan
              } }
            )[:data]

            if response['errors'].blank? && (data = response.dig('data', 'namespaceEligibility'))
              { success: true, data: data }
            else
              track_error(query, response)

              error(response['errors'])
            end
          end

          private

          def execute_graphql_query(params)
            response = ::Gitlab::HTTP.post(
              graphql_endpoint,
              headers: admin_headers,
              body: params.to_json
            )

            parse_response(response)
          end

          def graphql_endpoint
            EE::SUBSCRIPTIONS_GRAPHQL_URL
          end

          def track_error(query, response)
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
              SubscriptionPortal::Client::ResponseError.new("Received an error from CustomerDot"),
              query: query,
              response: response
            )
          end

          def error(errors = nil)
            {
              success: false,
              errors: errors
            }.compact
          end
        end
      end
    end
  end
end
