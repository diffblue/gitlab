# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::StateTransition, type: :model, feature_category: :vulnerability_management do
  let_it_be(:vulnerability) { create(:vulnerability) }

  subject { create(:vulnerability_state_transition, vulnerability: vulnerability) }

  it_behaves_like 'a BulkInsertSafe model', described_class do
    let(:vulnerability) { create(:vulnerability) }
    let(:current_time) { Time.zone.now }

    let(:valid_items_for_bulk_insertion) do
      build_list(
        :vulnerability_state_transition, 10,
        vulnerability: vulnerability,
        created_at: current_time,
        updated_at: current_time)
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User').inverse_of(:vulnerability_state_transitions) }
    it { is_expected.to belong_to(:vulnerability).class_name('Vulnerability').inverse_of(:state_transitions) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:vulnerability_id) }
    it { is_expected.to validate_presence_of(:from_state) }
    it { is_expected.to validate_presence_of(:to_state) }
    it { is_expected.to validate_length_of(:comment).is_at_most(50_000) }

    it "is expected to validate that :to_state differs from :from_state" do
      subject.from_state = subject.to_state

      expect(subject).to be_invalid
      expect do
        subject.save!
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        'Validation failed: To state must not be the same as from_state for the same dismissal_reason')
    end

    context 'when the last record contains a different dismissal_reason' do
      before do
        create(:vulnerability_state_transition, vulnerability: vulnerability, dismissal_reason: 'false_positive')
      end

      it 'does not fail the validation' do
        subject.from_state = subject.to_state
        subject.dismissal_reason = 'acceptable_risk'

        expect(subject).to be_valid
      end
    end
  end

  describe 'enums' do
    let(:vulnerability_states) do
      ::Enums::Vulnerability.vulnerability_states
    end

    let(:dismissal_reasons) do
      ::Vulnerabilities::DismissalReasonEnum.values
    end

    it { is_expected.to define_enum_for(:from_state).with_values(**vulnerability_states).with_prefix }
    it { is_expected.to define_enum_for(:to_state).with_values(**vulnerability_states).with_prefix }
    it { is_expected.to define_enum_for(:dismissal_reason).with_values(**dismissal_reasons) }
  end

  describe '.by_to_states' do
    let!(:dismissed_state_transition) do
      create(:vulnerability_state_transition,
             vulnerability: vulnerability,
             from_state: :detected,
             to_state: :dismissed)
    end

    let!(:resolved_state_transition) do
      create(:vulnerability_state_transition,
             vulnerability: vulnerability,
             from_state: :detected,
             to_state: :resolved)
    end

    let(:states) { %w[dismissed] }

    subject { described_class.by_to_states(states) }

    it 'returns state transitions matching the given states' do
      is_expected.to contain_exactly(dismissed_state_transition)
    end
  end

  context 'when loose foreign key on vulnerability_state_transitions.state_changed_at_pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:vulnerability_state_transition, pipeline: parent) }
    end
  end
end
