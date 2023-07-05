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
      allow_any_instance_of(Project) # rubocop:disable RSpec/AnyInstanceOf
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

  describe 'diffLlmSummaries' do
    let(:mr_fields) { "diffLlmSummaries { nodes { mergeRequestDiffId content } }" }

    context 'when there are MergeRequest::DiffLlmSummary records associated to MR' do
      let!(:mr_diff_1) { create(:merge_request_diff, merge_request: merge_request) }
      let!(:mr_diff_2) { create(:merge_request_diff, merge_request: merge_request) }
      let!(:mr_diff_summary_1) { create(:merge_request_diff_llm_summary, merge_request_diff: mr_diff_1) }
      let!(:mr_diff_summary_2) { create(:merge_request_diff_llm_summary, merge_request_diff: mr_diff_2) }

      it 'returns the diff summaries' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_graphql_data).to eq({
          'diffLlmSummaries' => {
            'nodes' => [
              {
                'mergeRequestDiffId' => mr_diff_2.id.to_s,
                'content' => mr_diff_summary_2.content
              },
              {
                'mergeRequestDiffId' => mr_diff_1.id.to_s,
                'content' => mr_diff_summary_1.content
              }
            ]
          }
        })
      end
    end

    context 'when there are no MergeRequest::DiffLlmSummary records associated to MR' do
      it 'returns empty nodes' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_graphql_data).to eq({
          'diffLlmSummaries' => {
            'nodes' => []
          }
        })
      end
    end
  end

  describe 'mergeRequestDiffs' do
    let(:mr_fields) do
      <<-GQL
      mergeRequestDiffs {
        nodes {
          diffLlmSummary {
            mergeRequestDiffId
            content
            user {
              id
            }
          }
          reviewLlmSummaries {
            nodes {
              mergeRequestDiffId
              content
              user {
                id
              }
              reviewer {
                id
              }
            }
          }
        }
      }
      GQL
    end

    let_it_be(:merge_request) { create(:merge_request, :skip_diff_creation, source_project: project) }
    let_it_be(:mr_diff_1) { create(:merge_request_diff, merge_request: merge_request) }
    let_it_be(:mr_diff_2) { create(:merge_request_diff, merge_request: merge_request) }

    context 'when there are diff and review summaries associated to MR diffs' do
      let_it_be(:mr_diff_summary_1) { create(:merge_request_diff_llm_summary, merge_request_diff: mr_diff_1) }
      let_it_be(:mr_diff_summary_2) { create(:merge_request_diff_llm_summary, merge_request_diff: mr_diff_2) }
      let_it_be(:mr_review_summary_1) { create(:merge_request_review_llm_summary, merge_request_diff: mr_diff_1) }
      let_it_be(:mr_review_summary_2) { create(:merge_request_review_llm_summary, merge_request_diff: mr_diff_2) }

      it 'returns the diff and review summaries' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_graphql_data).to eq({
          'mergeRequestDiffs' => {
            'nodes' => [
              {
                'diffLlmSummary' => {
                  'mergeRequestDiffId' => mr_diff_2.id.to_s,
                  'content' => mr_diff_summary_2.content,
                  'user' => {
                    'id' => mr_diff_summary_2.user.to_gid.to_s
                  }
                },
                'reviewLlmSummaries' => {
                  'nodes' => [
                    {
                      'mergeRequestDiffId' => mr_diff_2.id.to_s,
                      'content' => mr_review_summary_2.content,
                      'user' => {
                        'id' => mr_review_summary_2.user.to_gid.to_s
                      },
                      'reviewer' => {
                        'id' => mr_review_summary_2.reviewer.to_gid.to_s
                      }
                    }
                  ]
                }
              },
              {
                'diffLlmSummary' => {
                  'mergeRequestDiffId' => mr_diff_1.id.to_s,
                  'content' => mr_diff_summary_1.content,
                  'user' => {
                    'id' => mr_diff_summary_1.user.to_gid.to_s
                  }
                },
                'reviewLlmSummaries' => {
                  'nodes' => [
                    {
                      'mergeRequestDiffId' => mr_diff_1.id.to_s,
                      'content' => mr_review_summary_1.content,
                      'user' => {
                        'id' => mr_review_summary_1.user.to_gid.to_s
                      },
                      'reviewer' => {
                        'id' => mr_review_summary_1.reviewer.to_gid.to_s
                      }
                    }
                  ]
                }
              }
            ]
          }
        })
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        post_graphql(query, current_user: current_user) # warm-up

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        expect_graphql_errors_to_be_empty

        mr_diff_3 = create(:merge_request_diff, merge_request: merge_request)
        create(:merge_request_diff_llm_summary, merge_request_diff: mr_diff_3)
        create(:merge_request_review_llm_summary, merge_request_diff: mr_diff_3)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
        expect_graphql_errors_to_be_empty
      end
    end

    context 'when there are no diff and review summaries associated to MR diffs' do
      it 'returns empty nodes' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_graphql_data).to eq({
          'mergeRequestDiffs' => {
            'nodes' => [
              {
                'diffLlmSummary' => nil,
                'reviewLlmSummaries' => { 'nodes' => [] }
              },
              {
                'diffLlmSummary' => nil,
                'reviewLlmSummaries' => { 'nodes' => [] }
              }
            ]
          }
        })
      end
    end
  end
end
