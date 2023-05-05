# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BranchPushService, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:user) { create(:user) }

  let(:blankrev)   { Gitlab::Git::BLANK_SHA }
  let(:oldrev)     { sample_commit.parent_id }
  let(:newrev)     { sample_commit.id }
  let(:ref)        { 'refs/heads/master' }

  let(:params) do
    { change: { oldrev: oldrev, newrev: newrev, ref: ref } }
  end

  subject do
    described_class.new(project, user, params)
  end

  context 'with pull project' do
    let_it_be(:project) { create(:project, :repository, :mirror) }

    before do
      allow(project.repository).to receive(:commit).and_call_original
      allow(project.repository).to receive(:commit).with("master").and_return(nil)
    end

    context 'deleted branch' do
      let(:newrev) { blankrev }

      it 'handles when remote branch exists' do
        expect(project.repository).to receive(:commit).with("refs/remotes/upstream/master").and_return(sample_commit)

        subject.execute
      end
    end

    context 'ElasticSearch indexing', :elastic, :clean_gitlab_redis_shared_state, feature_category: :global_search do
      before do
        stub_ee_application_setting(elasticsearch_indexing?: true)
      end

      it 'runs ElasticCommitIndexerWorker' do
        expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id)

        subject.execute
      end

      it "triggers indexer when push to default branch", :sidekiq_might_not_need_inline do
        expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run)

        subject.execute
      end

      context 'when push to non-default branch' do
        let(:ref) { 'refs/heads/other' }

        it 'does not trigger indexer when push to non-default branch' do
          expect_any_instance_of(Gitlab::Elastic::Indexer).not_to receive(:run)

          subject.execute
        end
      end

      context 'when limited indexing is on' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        context 'when the project is not enabled specifically' do
          it 'does not run ElasticCommitIndexerWorker' do
            expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

            subject.execute
          end
        end

        context 'when a project is enabled specifically' do
          before do
            create :elasticsearch_indexed_project, project: project
          end

          it 'runs ElasticCommitIndexerWorker' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id)

            subject.execute
          end
        end

        context 'when a group is enabled' do
          let(:group) { create(:group) }
          let(:project) { create(:project, :repository, :mirror, group: group) }

          before do
            create :elasticsearch_indexed_namespace, namespace: group
          end

          it 'runs ElasticCommitIndexerWorker' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id)

            subject.execute
          end
        end
      end
    end

    context 'with Zoekt indexing', feature_category: :global_search do
      let(:use_zoekt) { true }

      before do
        allow(project).to receive(:use_zoekt?).and_return(use_zoekt)
      end

      it 'triggers async_update_zoekt_index' do
        expect(project.repository).to receive(:async_update_zoekt_index)

        subject.execute
      end

      context 'when pushing to a non-default branch' do
        let(:ref) { 'refs/heads/other' }

        it 'does not trigger async_update_zoekt_index' do
          expect(project.repository).not_to receive(:async_update_zoekt_index)

          subject.execute
        end
      end

      context 'when index_code_with_zoekt is disabled' do
        before do
          stub_feature_flags(index_code_with_zoekt: false)
        end

        it 'does not trigger async_update_zoekt_index' do
          expect(project.repository).not_to receive(:async_update_zoekt_index)

          subject.execute
        end
      end

      context 'when zoekt is not enabled for the project' do
        let(:use_zoekt) { false }

        it 'does not trigger async_update_zoekt_index' do
          expect(project.repository).not_to receive(:async_update_zoekt_index)

          subject.execute
        end
      end
    end

    context 'External pull requests' do
      it 'runs UpdateExternalPullRequestsWorker' do
        expect(UpdateExternalPullRequestsWorker).to receive(:perform_async).with(project.id, user.id, ref)

        subject.execute
      end

      context 'when project is not mirror' do
        before do
          allow(project).to receive(:mirror?).and_return(false)
        end

        it 'does nothing' do
          expect(UpdateExternalPullRequestsWorker).not_to receive(:perform_async)

          subject.execute
        end
      end

      context 'when param skips pipeline creation' do
        before do
          params[:create_pipelines] = false
        end

        it 'does nothing' do
          expect(UpdateExternalPullRequestsWorker).not_to receive(:perform_async)

          subject.execute
        end
      end
    end

    context 'Product Analytics' do
      using RSpec::Parameterized::TableSyntax

      where(:flag_enabled, :default_branch, :licence_available, :called) do
        true  | 'master' | true  | true
        true  | 'master' | false | false
        true  | 'other'  | true  | false
        true  | 'other'  | false | false
        false | 'master' | true  | false
        false | 'master' | false | false
        false | 'other'  | true  | false
        false | 'other'  | false | false
      end

      before do
        stub_feature_flags(product_analytics_dashboards: flag_enabled)
        stub_licensed_features(product_analytics: licence_available)
        allow(project).to receive(:default_branch).and_return(default_branch)
      end

      with_them do
        it 'enqueues the worker if appropriate' do
          if called
            expect(::ProductAnalytics::PostPushWorker).to receive(:perform_async).once
          else
            expect(::ProductAnalytics::PostPushWorker).not_to receive(:perform_async)
          end

          subject.execute
        end
      end
    end
  end
end
