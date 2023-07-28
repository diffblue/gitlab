# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiff, feature_category: :geo_replication do
  using RSpec::Parameterized::TableSyntax
  include EE::GeoHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:other_project) { create(:project, :repository) }

  it { is_expected.to respond_to(:log_geo_deleted_event) }

  before do
    stub_external_diffs_setting(enabled: true)
  end

  include_examples 'a replicable model with a separate table for verification state' do
    let(:verifiable_model_record) { build(:merge_request_diff, :external, external_diff_store: ::ObjectStorage::Store::LOCAL) }
    let(:unverifiable_model_record) { build(:merge_request_diff) }
  end

  describe '#after_save' do
    let(:mr_diff) { build(:merge_request_diff, :external, external_diff_store: ::ObjectStorage::Store::LOCAL) }

    context 'when diff is stored externally and locally' do
      it 'does not create verification details when diff is without files' do
        mr_diff[:state] = :without_files

        expect { mr_diff.save! }.not_to change { MergeRequestDiffDetail.count }
      end

      it 'does not create verification details when diff is empty' do
        mr_diff[:state] = :empty

        expect { mr_diff.save! }.not_to change { MergeRequestDiffDetail.count }
      end

      it 'creates verification details' do
        # This stub has to be set for the whole '#after_save' block but due to the bug
        # https://gitlab.com/gitlab-org/gitlab/-/issues/413852
        # this specs will fail in that case. Move it up when the bug is fixed
        stub_primary_node
        mr_diff[:state] = :collected

        expect { mr_diff.save! }.to change { MergeRequestDiffDetail.count }.by(1)
      end

      context 'for a remote stored diff' do
        before do
          allow_next_instance_of(MergeRequestDiff) do |mr_diff|
            allow(mr_diff).to receive(:update_external_diff_store).and_return(true)
          end
        end

        it 'does not create verification details' do
          mr_diff[:state] = :collected
          mr_diff[:external_diff_store] = ::ObjectStorage::Store::REMOTE

          expect { mr_diff.save! }.not_to change { MergeRequestDiffDetail.count }
        end
      end
    end

    context 'when diff is not stored externally' do
      it 'does not create verification details' do
        expect { create(:merge_request_diff, stored_externally: false) }.not_to change { MergeRequestDiffDetail.count }
      end
    end
  end

  describe 'preprare_diff_summary' do
    let(:merge_request) { create(:merge_request, :skip_diff_creation, target_project: project, source_project: project) }
    let(:diff_with_commits) { create(:merge_request_diff, merge_request: merge_request) }

    before do
      stub_licensed_features(summarize_mr_changes: true)
    end

    context 'when openai_experimentation feature flag is off' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it 'does not call the summarize worker' do
        expect(::MergeRequests::Llm::SummarizeMergeRequestWorker).not_to receive(:new)

        diff_with_commits
      end
    end

    context 'when summarize_diff_automatically feature flag is off' do
      before do
        stub_feature_flags(summarize_diff_automatically: false)
      end

      it 'does not call the summarize worker' do
        expect(::MergeRequests::Llm::SummarizeMergeRequestWorker).not_to receive(:new)

        diff_with_commits
      end
    end

    context 'when summarize_mr_change feature not avaliable' do
      before do
        stub_licensed_features(summarize_mr_changes: false)
      end

      it 'does not call the summarize worker' do
        expect(::MergeRequests::Llm::SummarizeMergeRequestWorker).not_to receive(:new)

        diff_with_commits
      end
    end

    context 'when the llm_bot does not exist' do
      before do
        allow(User).to receive(:llm_bot).and_return(nil)
      end

      it 'does not call the summarize worker' do
        expect(::MergeRequests::Llm::SummarizeMergeRequestWorker).not_to receive(:new)

        diff_with_commits
      end
    end

    context 'when the diff is not merge_head' do
      let(:diff_with_commits) { create(:merge_request_diff, :merge_head) }

      it 'does not call the summarize worker' do
        expect(::MergeRequests::Llm::SummarizeMergeRequestWorker).not_to receive(:new)

        diff_with_commits
      end
    end

    context 'when llm merge requests diff service is not enabled' do
      before do
        allow(Llm::MergeRequests::SummarizeDiffService)
          .to receive(:enabled?)
          .at_least(:once)
          .with(group: project.root_ancestor, user: User.llm_bot)
          .and_return(false)
      end

      it 'does not call the summarize worker' do
        expect(::MergeRequests::Llm::SummarizeMergeRequestWorker).not_to receive(:new)

        diff_with_commits
      end
    end

    context 'when all the feature flags are on and the bot available' do
      before do
        allow(Llm::MergeRequests::SummarizeDiffService)
          .to receive(:enabled?)
          .at_least(:once)
          .with(group: project.root_ancestor, user: User.llm_bot)
          .and_return(true)
      end

      it 'calls the summarize worker' do
        allow(::MergeRequests::Llm::SummarizeMergeRequestWorker).to receive(:perform_async)

        diff_with_commits

        expect(::MergeRequests::Llm::SummarizeMergeRequestWorker).to have_received(:perform_async)
          .with(User.llm_bot.id, { type: ::MergeRequests::Llm::SummarizeMergeRequestWorker::PREPARE_DIFF_SUMMARY, diff_id: diff_with_commits.id })
      end
    end
  end

  describe '.search' do
    let_it_be(:merge_request_diff1) { create(:merge_request_diff) }
    let_it_be(:merge_request_diff2) { create(:merge_request_diff) }
    let_it_be(:merge_request_diff3) { create(:merge_request_diff) }

    context 'when search query is empty' do
      it 'returns all records' do
        result = described_class.search('')

        expect(result).to contain_exactly(merge_request_diff1, merge_request_diff2, merge_request_diff3)
      end
    end

    context 'when search query is not empty' do
      context 'without matches' do
        it 'filters all records' do
          result = described_class.search('something_that_does_not_exist')

          expect(result).to be_empty
        end
      end

      context 'with matches by attributes' do
        context 'for external_diff attribute' do
          before do
            merge_request_diff1.update_column(:external_diff, 'diff-105')
            merge_request_diff2.update_column(:external_diff, 'diff-106')
            merge_request_diff3.update_column(:external_diff, 'diff-107')
          end

          it 'returns merge_request_diffs limited to 1000 records' do
            expect_any_instance_of(described_class) do |instance|
              expect(instance).to receive(:limit).and_return(1000)
            end

            result = described_class.search('diff-106')

            expect(result).to contain_exactly(merge_request_diff2)
          end
        end
      end
    end
  end

  describe '.with_files_stored_locally' do
    it 'includes states with local storage' do
      create(:merge_request, source_project: project)

      expect(described_class.with_files_stored_locally).to have_attributes(count: 1)
    end

    it 'excludes states with local storage' do
      stub_external_diffs_object_storage(ExternalDiffUploader, direct_upload: true)

      create(:merge_request, source_project: project)

      expect(described_class.with_files_stored_locally).to have_attributes(count: 0)
    end
  end

  describe '.has_external_diffs' do
    it 'only includes diffs with files' do
      diff_with_files = create(:merge_request).merge_request_diff
      create(:merge_request, :without_diffs)

      expect(described_class.has_external_diffs).to contain_exactly(diff_with_files)
    end

    it 'only includes externally stored diffs' do
      external_diff = create(:merge_request).merge_request_diff

      stub_external_diffs_setting(enabled: false)

      create(:merge_request, :without_diffs)

      expect(described_class.has_external_diffs).to contain_exactly(external_diff)
    end
  end

  describe '.project_id_in' do
    it 'only includes diffs for the provided projects' do
      diff = create(:merge_request, source_project: project).merge_request_diff
      other_diff = create(:merge_request, source_project: other_project).merge_request_diff
      create(:merge_request)

      expect(described_class.project_id_in([project, other_project])).to contain_exactly(diff, other_diff)
    end
  end

  describe '.replicables_for_current_secondary' do
    context 'without selective sync or object storage' do
      let(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(secondary)
      end

      it 'excludes diffs stored in the database' do
        stub_external_diffs_setting(enabled: false)

        create(:merge_request, source_project: project)

        expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to be_empty
      end

      it 'excludes empty diffs' do
        create(:merge_request, source_project: create(:project))

        expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to be_empty
      end
    end

    where(:selective_sync_enabled, :object_storage_sync_enabled, :diff_in_object_storage, :synced_states) do
      true  | true  | true  | 1
      true  | true  | false | 1
      true  | false | true  | 0
      true  | false | false | 1
      false | false | false | 2
      false | false | true  | 0
      false | true  | true  | 2
      false | true  | false | 2
      true  | true  | false | 1
    end

    with_them do
      let(:secondary) do
        node = build(:geo_node, sync_object_storage: object_storage_sync_enabled)

        if selective_sync_enabled
          node.selective_sync_type = 'namespaces'
          node.namespaces = [group]
        end

        node.save!
        node
      end

      before do
        stub_current_geo_node(secondary)

        stub_external_diffs_object_storage(ExternalDiffUploader, direct_upload: true) if diff_in_object_storage

        create(:merge_request, source_project: project)
        create(:merge_request, source_project: other_project)
      end

      it 'returns the proper number of merge request diff states' do
        expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to have_attributes(count: synced_states)
      end
    end
  end

  describe '#latest_review_summary_from_reviewer' do
    let(:merge_request) { create(:merge_request, :skip_diff_creation) }
    let(:merge_request_2) { create(:merge_request, :skip_diff_creation) }
    let(:reviewer) { merge_request.author }
    let(:mr_diff_1) { create(:merge_request_diff, merge_request: merge_request) }
    let(:mr_diff_2) { create(:merge_request_diff, merge_request: merge_request_2) }
    let(:review_1) { create(:review, merge_request: merge_request, author: reviewer) }
    let(:review_2) { create(:review, merge_request: merge_request, author: reviewer) }
    let(:review_3) { create(:review, merge_request: merge_request) }
    let(:review_4) { create(:review, merge_request: merge_request_2, author: reviewer) }
    let!(:review_summary_1) { create(:merge_request_review_llm_summary, merge_request_diff: mr_diff_1, review: review_1) }
    let!(:review_summary_2) { create(:merge_request_review_llm_summary, merge_request_diff: mr_diff_1, review: review_2) }
    let!(:review_summary_3) { create(:merge_request_review_llm_summary, merge_request_diff: mr_diff_1, review: review_3) }
    let!(:review_summary_4) { create(:merge_request_review_llm_summary, merge_request_diff: mr_diff_2, review: review_4) }

    it 'returns the latest review summary from reviewer' do
      expect(mr_diff_1.latest_review_summary_from_reviewer(reviewer)).to eq(review_summary_2)
    end
  end
end
