# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::SecurityOrchestrationPolicies::LazyDastProfileAggregate do
  let_it_be(:current_user) { create(:user) }
  let(:query_ctx) do
    { current_user: current_user }
  end

  let_it_be(:project) { create(:project, namespace: current_user.namespace) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:other_dast_site_profile) { create(:dast_site_profile, project: dast_site_profile.project) }

  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: dast_site_profile.project) }
  let_it_be(:other_dast_scanner_profile) { create(:dast_scanner_profile, project: dast_site_profile.project) }

  let(:dast_profile) { dast_site_profile }
  let(:other_dast_profile) { other_dast_site_profile }

  describe '#initialize' do
    it 'adds the dast_profile to the lazy state' do
      subject = described_class.new(query_ctx, dast_profile)

      expect(subject.lazy_state[:dast_pending_profiles]).to eq [dast_profile]
      expect(subject.dast_profile).to eq dast_profile
    end

    it 'uses lazy_dast_profile_in_policies_aggregate to collect aggregates' do
      subject = described_class.new({ lazy_dast_profile_in_policies_aggregate: { dast_pending_profiles: [other_dast_profile], loaded_objects: {} } }, dast_profile)

      expect(subject.lazy_state[:dast_pending_profiles]).to match_array [other_dast_profile, dast_profile]
      expect(subject.dast_profile).to eq dast_profile
    end

    it 'raises ArgumentError when is not DastSiteProfile or DastScannerProfile' do
      expect { described_class.new(query_ctx, Project.new) }.to raise_error(ArgumentError, 'only DastSiteProfile or DastScannerProfile are allowed')
    end
  end

  describe '#execute' do
    subject { described_class.new(query_ctx, dast_profile) }

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    context 'if the record has already been loaded' do
      let(:fake_state) do
        { dast_pending_profiles: [], loaded_objects: { dast_profile => ['Dast Profile Name'] } }
      end

      it 'does not make the query again' do
        expect(::Security::OrchestrationPolicyConfiguration).not_to receive(:for_project)

        subject.execute
      end
    end

    context 'if the record has not been loaded' do
      let(:fake_state) do
        { dast_pending_profiles: Set.new([dast_profile, other_dast_profile]), loaded_objects: {} }
      end

      let(:fake_policy_configuration) do
        instance_double(::Security::OrchestrationPolicyConfiguration,
          project_id: dast_profile.project_id,
          active_policy_names_with_dast_site_profile: ['Dast Site Name'],
          active_policy_names_with_dast_scanner_profile: ['Dast Scanner Name']
        )
      end

      before do
        allow_next_found_instance_of(Project) do |project|
          allow(project).to receive(:all_security_orchestration_policy_configurations).and_return([fake_policy_configuration])
        end
      end

      context 'when Dast Site profile is provided' do
        it 'makes the query' do
          expect(subject.execute).to eq(['Dast Site Name'])
        end
      end

      context 'when Dast Scanner profile is provided' do
        let(:dast_profile) { dast_scanner_profile }
        let(:other_dast_profile) { other_dast_scanner_profile }

        it 'makes the query' do
          expect(subject.execute).to eq(['Dast Scanner Name'])
        end
      end

      it 'clears the pending IDs' do
        subject.execute

        expect(subject.lazy_state[:dast_pending_profiles]).to be_empty
      end
    end
  end
end
