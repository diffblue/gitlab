# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SubscriptionPortal::Clients::Graphql, feature_category: :billing_and_payments do
  let(:client) { Gitlab::SubscriptionPortal::Client }
  let(:graphql_url) { ::Gitlab::Routing.url_helpers.subscription_portal_graphql_url }

  describe '#activate' do
    let(:license_key) { 'license_key' }

    it 'returns success' do
      expect(client).to receive(:execute_graphql_query).and_return(
        {
          success: true,
          data: {
            "data" => {
              "cloudActivationActivate" => {
                "licenseKey" => license_key,
                "errors" => [],
                "futureSubscriptions" => []
              }
            }
          }
        }
      )

      result = client.activate('activation_code_abc', automated: false)

      expect(result).to eq({ license_key: license_key, success: true, future_subscriptions: [] })
    end

    context 'when there are future subscriptions' do
      it 'returns success' do
        future_date = 4.days.from_now.to_date

        expect(client).to receive(:execute_graphql_query).and_return(
          {
            success: true,
            data: {
              "data" => {
                "cloudActivationActivate" => {
                  "licenseKey" => license_key,
                  "errors" => [],
                  "futureSubscriptions" => [
                    {
                      "cloudLicenseEnabled" => true,
                      "offlineCloudLicenseEnabled" => false,
                      "plan" => "ultimate",
                      "name" => "User Example",
                      "company" => "Example Inc",
                      "email" => "user@example.com",
                      "startsAt" => future_date.to_s,
                      "expiresAt" => (future_date + 1.year).to_s,
                      "usersInLicenseCount" => 10
                    }
                  ]
                }
              }
            }
          }
        )

        result = client.activate('activation_code_abc', automated: false)

        expect(result).to eq(
          {
            license_key: license_key,
            success: true,
            future_subscriptions: [
              {
                "cloud_license_enabled" => true,
                "offline_cloud_license_enabled" => false,
                "plan" => "ultimate",
                "name" => "User Example",
                "company" => "Example Inc",
                "email" => "user@example.com",
                "starts_at" => future_date.to_s,
                "expires_at" => (future_date + 1.year).to_s,
                "users_in_license_count" => 10
              }
            ]
          }
        )
      end
    end

    context 'when the activation code is invalid' do
      it 'returns failure' do
        expect(client).to receive(:execute_graphql_query).and_return(
          {
            success: true,
            data: {
              "data" => {
                "cloudActivationActivate" => {
                  "licenseKey" => nil,
                  "errors" => ["invalid activation code"],
                  "futureSubscriptions" => []
                }
              }
            }
          }
        )

        result = client.activate('activation_code_abc', automated: false)

        expect(result).to eq({ errors: ["invalid activation code"], success: false })
      end
    end

    context 'when remote server returns error' do
      it 'returns connectivity error' do
        stub_request(:any, graphql_url)
          .to_return(status: [500, "Internal Server Error"], body: 'body')
        allow(Gitlab::ErrorTracking).to receive(:log_exception)

        result = client.activate('activation_code_abc', automated: false)

        expect(result).to eq({ errors: described_class::CONNECTIVITY_ERROR, success: false })

        expect(Gitlab::ErrorTracking).to have_received(:log_exception).with(
          instance_of(::Gitlab::SubscriptionPortal::Client::ResponseError),
          {
            status: 500,
            message: "Internal Server Error",
            body: 'body'
          }
        )
      end
    end

    context 'when the remote server is unreachable' do
      it 'returns connectivity error' do
        stub_request(:any, graphql_url).to_timeout
        allow(Gitlab::ErrorTracking).to receive(:log_exception)

        result = client.activate('activation_code_abc', automated: false)

        expect(result).to eq({ errors: described_class::CONNECTIVITY_ERROR, success: false })
        expect(Gitlab::ErrorTracking).to have_received(:log_exception).with(kind_of(Timeout::Error))
      end
    end
  end

  describe '#plan_upgrade_offer' do
    let(:namespace_id) { 111 }

    subject(:plan_upgrade_offer) { client.plan_upgrade_offer(namespace_id: namespace_id) }

    context 'when the response contains errors' do
      before do
        expect(client).to receive(:execute_graphql_query).and_return(response)
      end

      let(:response) do
        {
          success: true,
          data: {
            'errors' => [{ 'message' => 'this will be ignored' }]
          }
        }
      end

      it 'returns a failure' do
        expect(plan_upgrade_offer).to eq({ success: false })
      end
    end

    context 'when the response does not contain errors' do
      using RSpec::Parameterized::TableSyntax

      where(:eligible, :assisted_plan_id, :free_plan_id) do
        true | '111111' | '111111'
        true | '111111' | nil
        true | nil      | '111111'
      end

      with_them do
        before do
          allow(client).to receive(:execute_graphql_query).and_return({
              success: true,
              data: { "data" => { "subscription" => {
                "eoaStarterBronzeEligible" => eligible,
                "assistedUpgradePlanId" => assisted_plan_id,
                "freeUpgradePlanId" => free_plan_id
                } } }
          })
        end

        it 'returns the correct response' do
          expect(plan_upgrade_offer).to eq({
            success: true,
            eligible_for_free_upgrade: eligible,
            assisted_upgrade_plan_id: assisted_plan_id,
            free_upgrade_plan_id: free_plan_id
          })
        end
      end

      context 'when subscription is nil' do
        before do
          allow(client).to receive(:execute_graphql_query).and_return({
            success: true,
            data: { "data" => { "subscription" => nil } }
          })
        end

        it 'returns the correct response' do
          expect(plan_upgrade_offer).to eq({
            success: true,
            eligible_for_free_upgrade: nil,
            assisted_upgrade_plan_id: nil,
            free_upgrade_plan_id: nil
          })
        end
      end
    end
  end

  describe '#subscription_last_term' do
    let(:query) do
      <<~GQL
        query($namespaceId: ID!) {
          subscription(namespaceId: $namespaceId) {
            lastTerm
          }
        }
      GQL
    end

    it 'returns success' do
      expected_args = {
        query: query,
        variables: {
          namespaceId: 'namespace-id'
        }
      }

      expected_response = {
        success: true,
        data: {
          "data" => {
            "subscription" => {
              "lastTerm" => true
            }
          }
        }
      }

      expect(client).to receive(:execute_graphql_query).with(expected_args).and_return(expected_response)

      result = client.subscription_last_term('namespace-id')

      expect(result).to eq({ success: true, last_term: true })
    end

    it 'returns failure' do
      error = "some error"
      expect(client).to receive(:execute_graphql_query).and_return(
        {
          success: false,
          data: {
            errors: error
          }
        }
      )

      result = client.subscription_last_term('failing-namespace-id')

      expect(result).to eq({ success: false, errors: error })
    end

    context 'with no namespace_id' do
      it 'returns failure' do
        expect(client).not_to receive(:execute_graphql_query)

        expect(client.subscription_last_term(nil)).to eq({ success: false, errors: 'Must provide a namespace ID' })
      end
    end
  end

  describe '#subscription_seat_usage_alerts_eligibility' do
    let(:query) do
      <<~GQL
        query($namespaceId: ID!) {
          subscription(namespaceId: $namespaceId) {
            eligibleForSeatUsageAlerts
          }
        }
      GQL
    end

    it 'returns success when the subscription can be found' do
      expected_args = {
        query: query,
        variables: {
          namespaceId: 'namespace-id'
        }
      }

      expected_response = {
        success: true,
        data: {
          "data" => {
            "subscription" => {
              "eligibleForSeatUsageAlerts" => true
            }
          }
        }
      }

      expect(client).to receive(:execute_graphql_query).with(expected_args).and_return(expected_response)

      result = client.subscription_seat_usage_alerts_eligibility('namespace-id')

      expect(result).to eq({ success: true, eligible_for_seat_usage_alerts: true })
    end

    it 'returns failure when the subscription cannot be found' do
      error = "some error"
      expect(client).to receive(:execute_graphql_query).and_return(
        {
          success: false,
          data: {
            errors: error
          }
        }
      )

      result = client.subscription_seat_usage_alerts_eligibility('failing-namespace-id')

      expect(result).to eq({ success: false, errors: error })
    end

    context 'with no namespace_id' do
      it 'returns failure' do
        expect(client).not_to receive(:execute_graphql_query)

        expect(client.subscription_seat_usage_alerts_eligibility(nil))
          .to eq({ success: false, errors: 'Must provide a namespace ID' })
      end
    end

    context 'when there is a network connectivity error' do
      it 'returns an error response' do
        allow(client).to receive(:execute_graphql_query).and_raise(HTTParty::Error)
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(kind_of(HTTParty::Error))

        request = client.subscription_seat_usage_alerts_eligibility('namespace-id')

        expect(request).to eq({ success: false, errors: "CONNECTIVITY_ERROR" })
      end
    end
  end

  describe '#get_plans' do
    subject { client.get_plans(tags: ['test-plan-id']) }

    let(:headers) do
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "X-Admin-Email" => "gl_com_api@gitlab.com",
        "X-Admin-Token" => "customer_admin_token"
      }
    end

    let(:params) do
      {
        variables: { tags: ['test-plan-id'] },
        query: <<~GQL
          query getPlans($tags: [PlanTag!]) {
            plans(planTags: $tags) {
              id
            }
          }
        GQL
      }
    end

    context 'when the request is successful' do
      it 'returns the data' do
        response = { data: { 'data' => { 'plans' => [{ 'id' => 1 }, { 'id' => 3 }] } } }

        expect(client).to receive(:http_post).with('graphql', headers, params).and_return(response)

        expect(subject).to eq(success: true, data: [{ 'id' => 1 }, { 'id' => 3 }])
      end
    end

    context 'when the request is unsuccessful' do
      it 'returns a failure response and logs the error' do
        response = {
          data: {
            "data" => { "plans" => nil },
            "errors" => [
              {
                "message" => "You must be logged in to access this resource",
                "locations" => [{ "line" => 2, "column" => 3 }],
                "path" => ["getPlans"]
              }
            ]
          }
        }

        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .with(
            a_kind_of(Gitlab::SubscriptionPortal::Client::ResponseError),
            query: params[:query],
            response: response[:data]
          )

        expect(client).to receive(:http_post).with('graphql', headers, params).and_return(response)

        expect(subject).to eq(
          success: false,
          errors: [{
            "locations" => [{ "column" => 3, "line" => 2 }],
            "message" => "You must be logged in to access this resource",
            "path" => ["getPlans"]
          }]
        )
      end
    end
  end

  describe '#filter_purchase_eligible_namespaces' do
    subject(:filter_purchase_eligible_namespaces) do
      client.filter_purchase_eligible_namespaces(
        user,
        [user_namespace, group_namespace, subgroup],
        plan_id: plan_id,
        any_self_service_plan: any_self_service_plan
      )
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:plan_id) { 'test-plan' }
    let_it_be(:any_self_service_plan) { true }
    let_it_be(:user_namespace) { user.namespace }
    let_it_be(:group_namespace) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group_namespace) }

    let(:headers) do
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "X-Admin-Email" => "gl_com_api@gitlab.com",
        "X-Admin-Token" => "customer_admin_token"
      }
    end

    let(:variables) do
      {
        customerUid: user.id,
        planId: plan_id,
        eligibleForPurchase: true,
        namespaces: [
          { id: user_namespace.id, parentId: nil, plan: "default", trial: false, kind: 'user', membersCountWithDescendants: nil },
          { id: group_namespace.id, parentId: nil, plan: "default", trial: false, kind: 'group', membersCountWithDescendants: 0 },
          { id: subgroup.id, parentId: group_namespace.id, plan: "default", trial: false, kind: 'group', membersCountWithDescendants: 0 }
        ]
      }
    end

    let(:params) do
      {
        variables: variables,
        query: <<~GQL
          query FilterEligibleNamespaces($customerUid: Int!, $namespaces: [GitlabNamespaceInput!]!, $planId: ID, $eligibleForPurchase: Boolean) {
            namespaceEligibility(customerUid: $customerUid, namespaces: $namespaces, planId: $planId, eligibleForPurchase: $eligibleForPurchase) {
              id
              accountId: zuoraAccountId
              subscription { name }
            }
          }
        GQL
      }
    end

    context 'when the response is successful' do
      it 'returns the namespace data', :aggregate_failures do
        response = {
          data: {
            'data' => {
              'namespaceEligibility' => [
                { 'id' => 1 }, { 'id' => 3 }
              ]
            }
          }
        }

        expect(client).to receive(:http_post).with('graphql', headers, params).and_return(response)

        expect(subject).to eq(success: true, data: [{ 'id' => 1 }, { 'id' => 3 }])
      end
    end

    context 'when the response is unsuccessful' do
      it 'returns the error message', :aggregate_failures do
        response = {
          data: {
            "data" => {
              "namespaceEligibility" => nil
            },
            "errors" => [
              {
                "message" => "You must be logged in to access this resource",
                "locations" => [{ "line" => 2, "column" => 3 }],
                "path" => ["namespaceEligibility"]
              }
            ]
          }
        }

        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .with(
            a_kind_of(Gitlab::SubscriptionPortal::Client::ResponseError),
            query: params[:query], response: response[:data])

        expect(client).to receive(:http_post).with('graphql', headers, params).and_return(response)

        expect(subject).to eq(
          success: false,
          errors: [{
            "locations" => [{ "column" => 3, "line" => 2 }],
            "message" => "You must be logged in to access this resource",
            "path" => ["namespaceEligibility"]
          }]
        )
      end
    end
  end

  describe '#update_namespace_name' do
    subject(:update_request) do
      client.update_namespace_name('namespace id', 'namespace name')
    end

    it 'returns success' do
      expect(client).to receive(:execute_graphql_query).and_return(
        {
          success: true,
          data: {
            'data' => {
              'orderNamespaceNameUpdate' => {
                'errors' => []
              }
            }
          }
        }
      )

      expect(update_request).to eq({ success: true })
    end

    it 'returns top level errors' do
      top_level_errors = ['Validation error', 'Errors in query execution']

      expect(client).to receive(:execute_graphql_query).and_return(
        {
          success: true,
          data: {
            'errors' => top_level_errors
          }
        }
      )

      expect(update_request).to eq({ errors: top_level_errors, success: false })
    end

    it 'returns errors as data' do
      errors_as_data = ['error updating the name']

      expect(client).to receive(:execute_graphql_query).and_return(
        {
          success: true,
          data: {
            'data' => {
              'orderNamespaceNameUpdate' => {
                'errors' => errors_as_data
              }
            }
          }
        }
      )

      expect(update_request).to eq({ errors: errors_as_data, success: false })
    end

    it 'returns connectivity error when remote server returns error' do
      stub_request(:any, graphql_url).to_return(status: [500, "Internal Server Error"])

      expect(update_request).to eq({ errors: described_class::CONNECTIVITY_ERROR, success: false })
    end

    it 'returns connectivity error when the remote server is unreachable' do
      stub_request(:any, graphql_url).to_timeout
      allow(Gitlab::ErrorTracking).to receive(:log_exception)

      expect(update_request).to eq({ errors: described_class::CONNECTIVITY_ERROR, success: false })
      expect(Gitlab::ErrorTracking).to have_received(:log_exception).with(kind_of(Timeout::Error))
    end
  end

  describe '#send_seat_overage_notification' do
    context 'when the subscription portal response is successful' do
      it 'returns successfully' do
        group = create(:group)
        owner_1 = create(:user)
        owner_2 = create(:user)

        group.add_owner(owner_1)
        group.add_owner(owner_2)

        expected_query_params = {
          variables: {
            namespaceId: group.id,
            maxSeatsUsed: 10,
            groupOwners: [
              { id: owner_1.id, email: owner_1.email, fullName: owner_1.name },
              { id: owner_2.id, email: owner_2.email, fullName: owner_2.name }
            ]
          },
          query: <<~GQL
            mutation($namespaceId: Int!, $maxSeatsUsed: Int!, $groupOwners: [GitlabEmailsUserInput!]!) {
              sendSeatOverageNotificationEmail(input: {
                glNamespaceId: $namespaceId,
                maxSeatsUsed: $maxSeatsUsed,
                groupOwners: $groupOwners
              }) {
                errors
              }
            }
          GQL
        }

        portal_response = {
          success: true,
          data: {
            "data" => {
              "sendSeatOverageNotificationEmail" => {
                "errors" => []
              }
            }
          }
        }

        expect(client).to receive(:execute_graphql_query).with(expected_query_params).and_return(portal_response)

        request = client.send_seat_overage_notification(
          group: group,
          max_seats_used: 10
        )

        expect(request).to eq({ success: true })
      end
    end

    context 'when the subscription portal response is unsuccessful' do
      it 'returns an error response' do
        expected_query_params = {
          variables: { namespaceId: 1, maxSeatsUsed: nil, groupOwners: [] },
          query: <<~GQL
            mutation($namespaceId: Int!, $maxSeatsUsed: Int!, $groupOwners: [GitlabEmailsUserInput!]!) {
              sendSeatOverageNotificationEmail(input: {
                glNamespaceId: $namespaceId,
                maxSeatsUsed: $maxSeatsUsed,
                groupOwners: $groupOwners
              }) {
                errors
              }
            }
          GQL
        }

        portal_response = {
          success: true,
          data: {
            "errors" => [
              {
                "message" => "Argument 'maxSeatsUsed' on InputObject 'SendSeatOverageNotificationEmailInput' has an invalid value (null). Expected type 'Int!'.",
                "locations" => [{ "line": 2, "column": 43 }],
                "path" => %w[mutation sendSeatOverageNotificationEmail input maxSeatsUsed],
                "extensions" => {
                  "code" => "argumentLiteralsIncompatible",
                  "typeName" => "InputObject",
                  "argumentName" => "maxSeatsUsed"
                }
              }
            ]
          }
        }

        expect(client).to receive(:execute_graphql_query).with(expected_query_params).and_return(portal_response)

        request = client.send_seat_overage_notification(group: build(:group, id: 1), max_seats_used: nil)

        expect(request[:success]).to be false
        expect(request[:errors]).not_to be_empty
      end
    end

    context 'when there is a network connectivity error' do
      it 'returns an error response' do
        allow(client).to receive(:execute_graphql_query).and_raise(HTTParty::Error)
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(kind_of(HTTParty::Error))

        request = client.send_seat_overage_notification(group: build(:group), max_seats_used: nil)

        expect(request).to eq({ success: false, errors: "CONNECTIVITY_ERROR" })
      end
    end
  end

  describe '#send_seat_overage_notification_batch' do
    let(:query_params) do
      {
        variables: { namespaces: [] },
        query: <<~GQL
        mutation($namespaces: [NamespaceSeatOverageInput!]) {
          sendSeatOverageNotificationEmail(input: {
            namespaces: $namespaces
          }) {
            errors
          }
        }
        GQL
      }
    end

    context 'when the subscription portal response is successful' do
      it 'returns successfully' do
        portal_response = {
          success: true,
          data: {
            "data" => {
              "sendSeatOverageNotificationEmail" => {
                "errors" => []
              }
            }
          }
        }

        expect(client).to receive(:execute_graphql_query).with(query_params).and_return(portal_response)

        request = client.send_seat_overage_notification_batch([])

        expect(request).to eq({ success: true })
      end
    end

    context 'when the subscription portal response is unsuccessful' do
      it 'returns an error response' do
        portal_response = {
          success: true,
          data: {
            "errors" => [
              {
                "message" => "Argument 'maxSeatsUsed' on InputObject 'SendSeatOverageNotificationEmailInput' has an invalid value (null). Expected type 'Int!'.",
                "locations" => [{ "line": 2, "column": 43 }],
                "path" => %w[mutation sendSeatOverageNotificationEmail input maxSeatsUsed],
                "extensions" => {
                  "code" => "argumentLiteralsIncompatible",
                  "typeName" => "InputObject",
                  "argumentName" => "maxSeatsUsed"
                }
              }
            ]
          }
        }

        expect(client).to receive(:execute_graphql_query).with(query_params).and_return(portal_response)

        request = client.send_seat_overage_notification_batch([])

        expect(request[:success]).to be false
        expect(request[:errors]).not_to be_empty
      end
    end

    context 'when there is a network connectivity error' do
      it 'returns an error response' do
        allow(client).to receive(:execute_graphql_query).and_raise(HTTParty::Error)
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(kind_of(HTTParty::Error))

        request = client.send_seat_overage_notification_batch(group: build(:group), max_seats_used: nil)

        expect(request).to eq({ success: false, errors: "CONNECTIVITY_ERROR" })
      end
    end
  end
end
