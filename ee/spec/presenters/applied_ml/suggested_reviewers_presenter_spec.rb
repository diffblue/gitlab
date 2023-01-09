# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppliedMl::SuggestedReviewersPresenter, feature_category: :code_review_workflow do
  let(:presenter) { described_class.new(predictions) }

  let(:predictions) do
    build(
      :predictions,
      accepted_reviewers: { reviewers: %w[bmarley] },
      suggested_reviewers: { reviewers: %w[bmarley swayne] }
    )
  end

  describe '#accepted' do
    subject { presenter.accepted }

    it { is_expected.to eq(['bmarley']) }
  end

  describe '#suggested' do
    subject { presenter.suggested }

    it { is_expected.to eq(%w[bmarley swayne]) }
  end
end
