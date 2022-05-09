# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::NetworkPolicyResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:time_now) { Time.utc(2021, 6, 16) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::NetworkPolicyType)
  end

  describe '#resolve' do
    subject(:resolve_network_policies) { resolve(described_class, obj: project, args: { environment_id: environment_id }, ctx: { current_user: user }) }

    let(:service_result) { instance_double(ServiceResponse, success?: true, payload: [policy, cilium_policy]) }
    let(:environment_id) { nil }

    context 'when NetworkPolicies::ResourcesService is executed successfully' do
      context 'when environment_id is not provided' do
        it 'returns empty array' do
          expect(resolve_network_policies).to eq([])
        end
      end

      context 'when environment_id is provided' do
        let(:environment_id) { global_id_of(model_name: 'Environment', id: 31) }

        it 'returns empty array' do
          expect(resolve_network_policies).to eq([])
        end
      end
    end
  end
end
