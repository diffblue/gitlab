# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners do
  include FakeBlobHelpers

  let!(:code_owner) { create(:user, username: 'owner-1') }
  let(:project) { create(:project, :repository) }
  let(:codeowner_content) { 'docs/CODEOWNERS @owner-1' }
  let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }
  let(:codeowner_blob_ref) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }

  before do
    project.add_developer(code_owner)

    allow_next_instance_of(Repository) do |repo|
      allow(repo).to receive(:code_owners_blob)
      .with(ref: codeowner_lookup_ref)
      .and_return(codeowner_blob)
    end
  end

  describe '.for_blob' do
    subject { described_class.for_blob(project, blob) }

    let(:branch) { TestEnv::BRANCH_SHA['with-codeowners'] }
    let(:blob) { project.repository.blob_at(branch, 'docs/CODEOWNERS') }
    let(:codeowner_lookup_ref) { branch }

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns users for a blob' do
        is_expected.to include(code_owner)
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns no users' do
        is_expected.to be_empty
      end
    end
  end

  describe '.sections' do
    subject { described_class.sections(project, branch) }

    let(:branch) { TestEnv::BRANCH_SHA['with-codeowners'] }
    let(:codeowner_lookup_ref) { branch }

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns sections' do
        is_expected.to match_array(['codeowners'])
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.optional_section?' do
    subject { described_class.optional_section?(project, branch, 'codeowners') }

    let(:branch) { TestEnv::BRANCH_SHA['with-codeowners'] }
    let(:codeowner_lookup_ref) { branch }

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns the optionality of the section' do
        is_expected.to eq(false)
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'does not call Loader' do
        expect(Gitlab::CodeOwners::Loader).not_to receive(:new)

        subject
      end
    end
  end

  describe '.fast_path_lookup and .slow_path_lookup' do
    let(:codeowner_lookup_ref) { 'with-codeowners' }
    let(:codeowner_content) { 'files/ruby/feature.rb @owner-1' }
    let(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'feature',
        target_project: project,
        target_branch: 'with-codeowners'
      )
    end

    before do
      stub_licensed_features(code_owners: true)
    end

    it 'returns equivalent results' do
      fast_results = described_class.entries_for_merge_request(merge_request).first

      allow_next_instance_of(MergeRequestDiff) do |mrd|
        expect(mrd).to receive(:overflow?) { true }
      end

      slow_results = described_class.entries_for_merge_request(merge_request).first

      expect(slow_results.users).to eq(fast_results.users)
      expect(slow_results.groups).to eq(fast_results.groups)
      expect(slow_results.pattern).to eq(fast_results.pattern)
    end
  end

  describe '.entries_for_merge_request' do
    subject(:entries) { described_class.entries_for_merge_request(merge_request, merge_request_diff: merge_request_diff) }

    let(:merge_request_diff) { nil }
    let(:codeowner_lookup_ref) { 'with-codeowners' }
    let(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'feature',
        target_project: project,
        target_branch: 'with-codeowners'
      )
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'runs mergeability check to reload merge_head_diff' do
        mergeability_service = instance_double(MergeRequests::MergeabilityCheckService)
        expect(mergeability_service).to receive(:execute).with(recheck: true)
        expect(MergeRequests::MergeabilityCheckService).to receive(:new).with(merge_request) { mergeability_service }

        expect(merge_request).to receive(:merge_head_diff).and_call_original

        entries
      end

      context 'when merge_head_diff exists' do
        before do
          expect(described_class).to receive(:fast_path_lookup) do |_, mrd|
            expect(mrd.state).to eq 'collected'
            expect(mrd.diff_type).to eq 'merge_head'
          end.and_return(modified_paths)
        end

        context 'when the changed file paths have matching code owners' do
          let(:modified_paths) { ['docs/CODEOWNERS'] }

          it 'returns owners for merge request' do
            expect(entries.first).to have_attributes(pattern: 'docs/CODEOWNERS', users: [code_owner])
          end
        end

        context 'when the changed file paths do not have matching code owners' do
          let(:modified_paths) { ['files/ruby/feature.rb'] }

          it 'returns an empty array' do
            expect(entries).to be_empty
          end
        end
      end

      context 'when merge_head_diff does not exist' do
        it 'falls back to an empty merge_request_diff' do
          mergeability_service = instance_double(MergeRequests::MergeabilityCheckService)
          expect(mergeability_service).to receive(:execute).with(recheck: true)
          expect(MergeRequests::MergeabilityCheckService).to receive(:new).with(merge_request).and_return(mergeability_service)
          expect(merge_request).to receive(:merge_head_diff).and_return(nil)

          expect(described_class).to receive(:fast_path_lookup) do |_, mrd|
            expect(mrd.state).to eq 'empty'
          end.and_return([])

          expect(entries).to be_empty
        end
      end

      context 'when merge_request_diff is specified' do
        let(:merge_request_diff) { merge_request.merge_request_diff }

        before do
          expect(described_class).to receive(:fast_path_lookup) do |_, mrd|
            expect(mrd.state).to eq 'collected'
            expect(mrd.diff_type).to eq 'regular'
          end.and_return(['docs/CODEOWNERS'])
        end

        it 'returns owners at the specified ref' do
          expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

          expect(entries.first).to have_attributes(pattern: 'docs/CODEOWNERS', users: [code_owner])
        end
      end

      context 'when the merge request is large (>1_000 files)' do
        before do
          allow_next_instance_of(MergeRequestDiff) do |mrd|
            allow(mrd).to receive(:overflow?) { true }
          end
        end

        it 'generates paths via .slow_path_lookup' do
          expect(described_class).not_to receive(:fast_path_lookup)
          expect(described_class).to receive(:slow_path_lookup).and_call_original

          entries
        end
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'skips reading codeowners and returns an empty array' do
        expect(described_class).not_to receive(:loader_for_merge_request)

        is_expected.to be_empty
      end
    end
  end
end
