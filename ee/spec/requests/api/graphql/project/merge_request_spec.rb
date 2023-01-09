# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge request information nested in a project', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }

  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:merge_request_graphql_data) { graphql_data_at(:project, :merge_request) }
  let(:mr_fields) { "suggestedReviewers { #{all_graphql_fields_for('SuggestedReviewersType')} }" }
  let(:suggested_reviewers) do
    {
      'version' => '0.0.0',
      'top_n' => 1,
      'reviewers' => %w[bmarley swayne]
    }
  end

  let(:accepted_reviewers) do
    {
      'reviewers' => %w[bmarley]
    }
  end

  let(:api_result) do
    {
      'accepted' => %w[bmarley],
      'suggested' => %w[bmarley swayne]
    }
  end

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:merge_request, { iid: merge_request.iid.to_s }, mr_fields)
    )
  end

  describe 'suggestedReviewers' do
    before do
      merge_request.build_predictions
      merge_request.predictions.update!(
        suggested_reviewers: suggested_reviewers,
        accepted_reviewers: accepted_reviewers
      )
      allow_any_instance_of(Project)  # rubocop:disable RSpec/AnyInstanceOf
        .to receive(:can_suggest_reviewers?).and_return(available)
    end

    shared_examples 'feature available' do
      it 'returns the right suggested reviewers' do
        post_graphql(query, current_user: current_user)

        expected_data = {
          'suggestedReviewers' => a_hash_including(api_result)
        }

        expect(merge_request_graphql_data).to include(expected_data)
      end
    end

    shared_examples 'feature unavailable' do
      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expected_data = {
          'suggestedReviewers' => nil
        }

        expect(merge_request_graphql_data).to include(expected_data)
      end
    end

    context 'when suggested reviewers is available for the project' do
      let(:available) { true }

      include_examples 'feature available'
    end

    context 'when suggested reviewers is not available for the project' do
      let(:available) { false }

      include_examples 'feature unavailable'
    end
  end
end
