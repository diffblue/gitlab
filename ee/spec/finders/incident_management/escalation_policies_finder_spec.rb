# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPoliciesFinder, feature_category: :incident_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project, name: 'unique identifier') }
  let_it_be(:escalation_policy_from_another_project) { create(:incident_management_escalation_policy) }

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(current_user, project, params).execute }

    context 'when feature is available' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      end

      context 'when user has permissions' do
        before do
          project.add_maintainer(current_user)
        end

        it 'returns project escalation policies' do
          is_expected.to contain_exactly(escalation_policy)
        end

        context 'when id given' do
          let(:params) { { id: escalation_policy.id } }

          it { is_expected.to contain_exactly(escalation_policy) }
        end

        context 'when exact_name is given' do
          let(:params) { { name: escalation_policy.name } }

          it { is_expected.to contain_exactly(escalation_policy) }

          context 'when the name does not match' do
            let(:params) { { name: 'another name' } }

            it { is_expected.to eq(IncidentManagement::EscalationPolicy.none) }
          end
        end

        context 'when search_name is given' do
          let(:params) { { name_search: 'ique iden' } }

          it { is_expected.to contain_exactly(escalation_policy) }

          context 'when the name does not match' do
            let(:params) { { name_search: 'not a matching search' } }

            it { is_expected.to eq(IncidentManagement::EscalationPolicy.none) }
          end
        end

        context 'when no params are given' do
          let(:params) { { id: nil, name: nil, name_search: nil } }

          it { is_expected.to contain_exactly(escalation_policy) }
        end
      end

      context 'when user has no permissions' do
        it { is_expected.to eq(IncidentManagement::EscalationPolicy.none) }
      end
    end

    context 'when feature is not avaiable' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: false)
      end

      it { is_expected.to eq(IncidentManagement::EscalationPolicy.none) }
    end
  end
end
