# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::StateTransition, type: :model, feature_category: :vulnerability_management do
  let_it_be(:vulnerability) { create(:vulnerability) }

  subject { create(:vulnerability_state_transitions, vulnerability: vulnerability) }

  it_behaves_like 'a BulkInsertSafe model', described_class do
    let(:vulnerability) { create(:vulnerability) }
    let(:current_time) { Time.zone.now }

    let(:valid_items_for_bulk_insertion) do
      build_list(
        :vulnerability_state_transitions, 10,
        vulnerability: vulnerability,
        created_at: current_time,
        updated_at: current_time)
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'associations' do
    it { is_expected.to belong_to(:vulnerability) }
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
      end.to raise_error ActiveRecord::RecordInvalid, "Validation failed: To state must not be the same as from_state"
    end
  end

  describe 'enums' do
    let(:vulnerability_states) do
      ::Enums::Vulnerability.vulnerability_states
    end

    it { is_expected.to define_enum_for(:from_state).with_values(**vulnerability_states).with_prefix }
    it { is_expected.to define_enum_for(:to_state).with_values(**vulnerability_states).with_prefix }
  end
end
