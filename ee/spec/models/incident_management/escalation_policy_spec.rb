# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPolicy, feature_category: :incident_management do
  subject(:escalation_policy) { build(:incident_management_escalation_policy) }

  it { is_expected.to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:rules) }
    it { is_expected.to have_many(:active_rules).order(elapsed_time_seconds: :asc, status: :asc).class_name('EscalationRule').inverse_of(:policy) }

    describe '.active_rules' do
      let(:policy) { create(:incident_management_escalation_policy) }
      let(:rule) { policy.rules.first }
      let(:removed_rule) { create(:incident_management_escalation_rule, :removed, policy: policy) }

      subject { policy.reload.active_rules }

      it { is_expected.to contain_exactly(rule) }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:project_id).with_message(/can only have one escalation policy/).on(:create) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_length_of(:name).is_at_most(72) }
    it { is_expected.to validate_length_of(:description).is_at_most(160) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:name).to(:project).with_prefix }
  end

  describe 'scopes' do
    let_it_be(:project) { create(:project) }
    let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }
    let_it_be(:other_policy) { create(:incident_management_escalation_policy, name: 'Other policy') }

    describe '.by_exact_name' do
      context 'with a valid name' do
        subject { described_class.by_exact_name('oTheR polIcY') }

        it 'returns the policy' do
          expect(subject).to contain_exactly(other_policy)
        end
      end

      context 'with name as nil' do
        subject { described_class.by_exact_name(nil) }

        it 'returns empty collection' do
          expect(subject).to be_empty
        end
      end
    end

    describe '.for_project' do
      subject { described_class.for_project(project) }

      it { is_expected.to contain_exactly(policy) }
    end

    describe '.search_by_name' do
      subject { described_class.search_by_name('other') }

      it 'does a case-insenstive search' do
        expect(subject).to contain_exactly(other_policy)
      end
    end
  end

  describe '#hook_attrs' do
    subject { escalation_policy.hook_attrs }

    it { is_expected.to eq({ id: escalation_policy.id, name: escalation_policy.name }) }
  end
end
