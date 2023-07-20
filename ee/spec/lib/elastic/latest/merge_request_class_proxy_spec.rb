# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::MergeRequestClassProxy, :elastic, :sidekiq_inline, feature_category: :global_search do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  subject { described_class.new(MergeRequest, use_separate_indices: true) }

  describe '#elastic_search' do
    describe 'search on basis of hidden attribute' do
      let_it_be(:query) { 'Foo' }
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:active_user) { create(:user) }
      let_it_be(:banned_user) { create(:user, :banned) }
      let_it_be(:active_user_mr) do
        create(:merge_request, title: query, target_project: project, source_project: project, author: active_user,
          state: :closed)
      end

      let_it_be(:banned_user_mr) do
        create(:merge_request, title: query, target_project: project, source_project: project, author: banned_user)
      end

      let_it_be(:user) { create(:user) }
      let(:options) { { current_user: current_user, project_ids: [project.id] } }
      let(:result) { subject.elastic_search(query, options: options) }

      before do
        Elastic::ProcessBookkeepingService.track!(active_user_mr, banned_user_mr)
        ensure_elasticsearch_index!
      end

      context 'when feature_flag hide_merge_requests_from_banned_users is disabled' do
        let(:current_user) { user }

        before do
          stub_feature_flags(hide_merge_requests_from_banned_users: false)
        end

        it 'includes merge_requests from the banned authors' do
          expect(elasticsearch_hit_ids(result)).to match_array([active_user_mr.id, banned_user_mr.id])
        end
      end

      context 'when feature_flag hide_merge_requests_from_banned_users is enabled' do
        context 'when current_user is non admin' do
          let(:current_user) { user }

          it 'does not include merge_requests from the banned authors' do
            expect(elasticsearch_hit_ids(result)).to match_array([active_user_mr.id])
          end

          it 'has the correct named queries' do
            result.response

            assert_named_queries(
              'merge_request:match:search_terms',
              'merge_request:archived:non_archived'
            )
          end

          context 'when search_issues_hide_archived_projects is disabled' do
            before do
              stub_feature_flags(search_merge_requests_hide_archived_projects: false)
            end

            it 'does not have a filter for archived' do
              result.response

              assert_named_queries('merge_request:match:search_terms', without: ['merge_request:archived:non_archived'])
            end
          end

          context 'when include_archived is set' do
            let(:options) { { include_archived: true } }

            it 'does not have a filter for archived' do
              result.response

              assert_named_queries('merge_request:match:search_terms', without: ['merge_request:archived:non_archived'])
            end
          end
        end

        context 'when current_user is anonymous' do
          let(:current_user) { nil }

          it 'does not include merge_requests from the banned authors' do
            expect(elasticsearch_hit_ids(result)).to match_array([active_user_mr.id])
          end
        end

        context 'when current_user is admin' do
          let_it_be(:admin) { create(:user, :admin) }
          let(:current_user) { admin }

          before do
            allow(admin).to receive(:can_admin_all_resources?).and_return(true)
          end

          it 'includes merge_requests from the banned authors' do
            expect(elasticsearch_hit_ids(result)).to match_array([active_user_mr.id, banned_user_mr.id])
          end
        end
      end
    end
  end
end
