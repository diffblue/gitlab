# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners, feature_category: :source_code_management do
  include FakeBlobHelpers

  let_it_be(:code_owner) { create(:user, username: 'owner-1') }

  describe 'mocked' do
    let(:project) { create(:project, :repository) }
    let(:codeowner_content) { 'docs/CODEOWNERS @owner-1' }
    let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }
    let(:codeowner_blob_ref) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }

    before do
      project.add_developer(code_owner)
      allow(project.repository).to receive(:code_owners_blob)
        .with(ref: codeowner_lookup_ref)
        .and_return(codeowner_blob)
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

    describe '.entries_for_merge_request' do
      subject(:entries) { described_class.entries_for_merge_request(merge_request, merge_request_diff: merge_request_diff) }

      let(:merge_request_diff) { nil }
      let(:codeowner_lookup_ref) { merge_request.target_branch }
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
        context 'when merge_head_diff exists' do
          before do
            merge_head_diff = instance_double(MergeRequestDiff)
            expect(merge_head_diff).to receive(:modified_paths).with(fallback_on_overflow: true).and_return(modified_paths)
            expect(merge_request).to receive(:merge_head_diff).and_return(merge_head_diff)
            expect(merge_request).not_to receive(:merge_request_diff).and_call_original
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
          before do
            expect(merge_request).to receive(:merge_head_diff).and_return(nil)
          end

          it 'falls back to merge_request_diff' do
            expect(merge_request.merge_request_diff).to receive(:modified_paths).with(fallback_on_overflow: true).and_call_original

            entries
          end
        end

        context 'when merge_request_diff is specified' do
          let(:merge_request_diff) { merge_request.merge_request_diff }
          let(:modified_paths) { ['docs/CODEOWNERS'] }

          before do
            expect(merge_request_diff).to receive(:modified_paths).with(fallback_on_overflow: true).and_return(modified_paths)
          end

          it 'returns owners at the specified ref' do
            expect(merge_request).not_to receive(:merge_head_diff)
            expect(entries.first).to have_attributes(pattern: 'docs/CODEOWNERS', users: [code_owner])
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

  describe '.entries_since_merge_request_commit' do
    let_it_be(:project) { create(:project, :custom_repo, files: { 'CODEOWNERS' => "*.rb @co1\n*.js @co2", 'file.rb' => '1' }) }
    let_it_be(:feature_sha1) { project.repository.create_file(code_owner, "another.rb", "2", message: "2", branch_name: 'feature') }
    let_it_be(:feature_sha2) { project.repository.create_file(code_owner, "some.js", "3", message: "3", branch_name: 'feature') }
    let_it_be(:feature_sha3) { project.repository.create_file(code_owner, "last.rb", "4", message: "4", branch_name: 'feature') }

    let_it_be(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'feature',
        target_project: project,
        target_branch: 'master'
      )
    end

    context 'without sha' do
      it 'identifies single codeowner entry' do
        entries = described_class.entries_since_merge_request_commit(merge_request)

        expect(entries.count).to be(1)
      end
    end

    context 'with sha' do
      it 'identifies single code owner entry' do
        entries = described_class.entries_since_merge_request_commit(merge_request, sha: feature_sha2)

        expect(entries.count).to be(1)
      end

      it 'identifies multiple code owner entries' do
        entries = described_class.entries_since_merge_request_commit(merge_request, sha: feature_sha1)

        expect(entries.count).to be(2)
      end
    end
  end
end
