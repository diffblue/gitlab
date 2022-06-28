# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::EnvironmentEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, refind: true) { create(:project, group: group) }
  let_it_be(:cluster) { create(:cluster_for_group, groups: [group]) }

  it 'inherits from API::Entities::EnvironmentBasic' do
    expect(described_class).to be < API::Entities::EnvironmentBasic
  end

  describe '#as_json' do
    let(:environment) { create(:environment, project: project) }
    let(:request) { double('request', current_user: user, cluster: cluster) }

    subject { described_class.new(environment, request: request).as_json }

    context 'with maintainer access' do
      before do
        group.add_maintainer(user)
      end

      context 'deploy board available' do
        before do
          stub_licensed_features(cluster_deployments: true)
        end

        it 'matches expected schema' do
          expect(subject.to_json).to match_schema('clusters/environment', dir: 'ee')
        end

        it 'exposes rollout_status' do
          expect(subject).to include(:rollout_status)
        end
      end

      context 'deploy board not available' do
        before do
          stub_licensed_features(cluster_deployments: false)
        end

        it 'matches expected schema' do
          expect(subject.to_json).to match_schema('clusters/environment', dir: 'ee')
        end

        it 'does not expose rollout_status' do
          expect(subject).not_to include(:rollout_status)
        end
      end
    end
  end
end
