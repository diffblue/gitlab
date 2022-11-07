# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::BuildPresenter do
  subject(:presenter) { described_class.new(ci_build) }

  describe '#callout_failure_message' do
    let(:ci_build) { build(:ee_ci_build, :protected_environment_failure) }

    it 'returns a verbose failure reason' do
      description = presenter.callout_failure_message

      expect(description).to eq 'The environment this job is deploying to is protected. ' \
                                'Only users with permission may successfully run this job.'
    end
  end

  describe '#retryable?' do
    subject { presenter.retryable? }

    let_it_be(:ci_build) { build(:ci_build, :canceled) }

    context 'when the build exists in a pipeline for merge train' do
      before do
        allow(ci_build).to receive(:merge_train_pipeline?) { true }
      end

      it { is_expected.to be false }
    end

    context 'when the build does not exist in a pipeline for merge train' do
      before do
        allow(ci_build).to receive(:merge_train_pipeline?) { false }
      end

      it { is_expected.to be true }
    end
  end
end
