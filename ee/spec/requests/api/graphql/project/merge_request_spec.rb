# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge request information nested in a project' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:project) { create(:project, :repository, :public, group: group) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:merge_request_graphql_data) { graphql_data_at(:project, :merge_request) }
  let(:mr_fields) { "suggestedReviewers { #{all_graphql_fields_for('SuggestedReviewersType')} }" }
  let(:api_result) do
    {
      'version' => '0.0.0',
      'topN' => 1,
      'reviewers' => ['root']
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

    context 'on GitLab.com', :saas do
      context 'with an ultimate plan' do
        let(:group) { create(:group_with_plan, plan: :ultimate_plan) }

        context 'with licensed feature available' do
          before do
            stub_application_setting(check_namespace_plan: true)
            stub_licensed_features(suggested_reviewers: true)
          end

          context 'with feature flag enabled' do
            before do
              stub_feature_flags(suggested_reviewers: project)
            end

            include_examples 'feature available'
          end

          context 'with feature flag disabled' do
            before do
              stub_feature_flags(suggested_reviewers: false, thing: project)
            end

            include_examples 'feature unavailable'
          end
        end

        context 'with licensed feature unavailable' do
          before do
            stub_licensed_features(suggested_reviewers: false)
          end

          context 'with feature flag enabled' do
            before do
              stub_feature_flags(suggested_reviewers: project)
            end

            include_examples 'feature unavailable'
          end

          context 'with feature flag disabled' do
            before do
              stub_feature_flags(suggested_reviewers: false, thing: project)
            end

            include_examples 'feature unavailable'
          end
        end
      end

      context 'with an non-ultimate plan' do
        let(:group) { create(:group_with_plan, plan: :premium_plan) }

        context 'with licensed feature unavailable' do
          before do
            stub_licensed_features(suggested_reviewers: false)
          end

          context 'with feature flag enabled' do
            before do
              stub_feature_flags(suggested_reviewers: project)
            end

            include_examples 'feature unavailable'
          end

          context 'with feature flag disabled' do
            before do
              stub_feature_flags(suggested_reviewers: false, thing: project)
            end

            include_examples 'feature unavailable'
          end
        end
      end
    end

    context 'on self managed' do
      let(:group) { create(:group) }

      include_examples 'feature unavailable'
    end
  end
end
