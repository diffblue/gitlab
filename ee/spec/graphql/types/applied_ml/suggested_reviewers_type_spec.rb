# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SuggestedReviewersType'], feature_category: :code_review_workflow do
  include GraphqlHelpers

  let(:fields) { %i[accepted created_at suggested updated_at] }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'field values' do
    let_it_be(:predictions) do
      create(
        :predictions,
        accepted_reviewers: { reviewers: %w[bmarley] },
        suggested_reviewers: { reviewers: %w[bmarley swayne] }
      )
    end

    let_it_be(:user) { build(:user) }

    subject { resolve_field(field_name, predictions, current_user: user) }

    describe 'accepted' do
      let(:field_name) { :accepted }

      it { is_expected.to eq(['bmarley']) }
    end

    describe 'suggested' do
      let(:field_name) { :suggested }

      it { is_expected.to eq(%w[bmarley swayne]) }
    end
  end
end
