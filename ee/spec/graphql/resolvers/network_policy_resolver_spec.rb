# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::NetworkPolicyResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:time_now) { Time.utc(2021, 6, 16) }

  let(:policy) do
    Gitlab::Kubernetes::NetworkPolicy.new(
      name: 'policy',
      namespace: 'another',
      creation_timestamp: time_now.iso8601,
      selector: { matchLabels: { role: 'db' } },
      ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }],
      environment_ids: [1, 2]
    )
  end

  let(:cilium_policy) do
    Gitlab::Kubernetes::CiliumNetworkPolicy.new(
      name: 'cilium_policy',
      namespace: 'another',
      creation_timestamp: time_now.iso8601,
      resource_version: '102',
      selector: { matchLabels: { role: 'db' } },
      ingress: [{ endpointFrom: [{ matchLabels: { project: 'myproject' } }] }],
      environment_ids: [3, 4]
    )
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::NetworkPolicyType)
  end

  describe '#resolve' do
    subject(:resolve_network_policies) { resolve(described_class, obj: project, args: { environment_id: environment_id }, ctx: { current_user: user }) }

    let(:service_result) { instance_double(ServiceResponse, success?: true, payload: [policy, cilium_policy]) }
    let(:environment_id) { nil }

    before do
      allow_next_instance_of(NetworkPolicies::ResourcesService) do |resources_service|
        allow(resources_service).to receive(:execute).and_return(service_result)
      end
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(threat_monitoring: false)
      end

      it 'raises ResourceNotAvailable error' do
        expect { resolve_network_policies }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(threat_monitoring: true)
      end

      context 'when NetworkPolicies::ResourcesService is not executed successfully' do
        let(:service_result) { instance_double(ServiceResponse, success?: false, message: 'Error fetching the result') }

        it 'raises Gitlab::Graphql::Errors::BaseError' do
          expect { resolve_network_policies }.to raise_error(Gitlab::Graphql::Errors::BaseError, 'Error fetching the result')
        end
      end

      context 'when NetworkPolicies::ResourcesService is executed successfully' do
        context 'when environment_id is not provided' do
          it 'uses NetworkPolicies::ResourceService without environment_id to fetch policies' do
            expect(NetworkPolicies::ResourcesService).to receive(:new).with(project: project, environment_id: nil)

            resolve_network_policies
          end
        end

        context 'when environment_id is provided' do
          let(:environment_id) { 'gid://gitlab/Environment/31' }

          it 'uses NetworkPolicies::ResourceService with resolved environment_id to fetch policies' do
            expect(NetworkPolicies::ResourcesService).to receive(:new).with(project: project, environment_id: '31')

            resolve_network_policies
          end
        end

        it 'returns scan execution policies' do
          expected_resolved = [
            {
              name: 'policy',
              kind: 'NetworkPolicy',
              namespace: 'another',
              enabled: true,
              yaml: policy.as_json[:manifest],
              updated_at: time_now,
              from_auto_devops: false,
              environment_ids: [1, 2],
              project: project
            },
            {
              name: 'cilium_policy',
              kind: 'CiliumNetworkPolicy',
              namespace: 'another',
              enabled: true,
              yaml: cilium_policy.as_json[:manifest],
              updated_at: time_now,
              from_auto_devops: false,
              environment_ids: [3, 4],
              project: project
            }
          ]
          expect(resolve_network_policies).to eq(expected_resolved)
        end
      end

      context 'when user is unauthorized' do
        let(:user) { create(:user) }

        it 'raises ResourceNotAvailable error' do
          expect { resolve_network_policies }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end
end
