# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::CostSetting, feature_category: :continuous_integration do
  let_it_be(:runner) { create_default(:ci_runner, :instance) }

  subject { described_class.new(runner: runner) }

  describe 'associations' do
    it { is_expected.to belong_to(:runner) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:os_contribution_factor) }
    it { is_expected.to validate_presence_of(:os_plan_factor) }
    it { is_expected.to validate_presence_of(:standard_factor) }
    it { is_expected.to validate_numericality_of(:standard_factor) }
    it { is_expected.to validate_numericality_of(:os_contribution_factor) }
    it { is_expected.to validate_numericality_of(:os_plan_factor) }

    context 'when the runner is shared' do
      specify { expect(subject).to be_valid }
    end

    context 'when the runner is not shared' do
      let(:runner) { build(:ci_runner, :project) }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages[:runner]).to include('must be shared')
      end
    end
  end
end
