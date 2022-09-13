# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::DiffCheck do
  include FakeBlobHelpers

  include_context 'push rules checks context'

  describe '#validate!' do
    let(:push_allowed) { false }

    before do
      allow(user_access).to receive(:can_push_to_branch?).and_return(push_allowed)
    end

    shared_examples_for "returns codeowners validation message" do
      it "returns an error message" do
        expect(validation_result).to include("Pushes to protected branches")
      end
    end

    context 'no push rules active' do
      let_it_be(:push_rule) { create(:push_rule) }

      it "does not attempt to check commits" do
        expect(subject).not_to receive(:process_commits)

        subject.validate!
      end
    end

    describe '#validate_code_owners?' do
      let_it_be(:push_rule) { create(:push_rule, file_name_regex: 'READ*') }

      let(:validate_code_owners) { subject.send(:validate_code_owners?) }
      let(:protocol) { 'ssh' }
      let(:push_allowed) { false }

      context 'when user can not push to the branch' do
        context 'when not updated from web' do
          it 'checks if the branch requires code owner approval' do
            expect(project).to receive(:branch_requires_code_owner_approval?).and_return(true)

            expect(validate_code_owners).to eq(true)
          end
        end

        context 'when updated from the web' do
          let(:protocol) { 'web' }

          it 'returns false' do
            expect(validate_code_owners).to eq(false)
          end
        end
      end

      context 'when a user can push to the branch' do
        let(:push_allowed) { true }

        it 'returns false' do
          expect(validate_code_owners).to eq(false)
        end
      end
    end

    describe "#validate_code_owners" do
      let!(:code_owner) { create(:user, username: "owner-1") }
      let(:project) { create(:project, :repository) }
      let(:codeowner_content) { "*.rb @#{code_owner.username}\ndocs/CODEOWNERS @owner-1\n*.js.coffee @owner-1" }
      let(:codeowner_blob) { fake_blob(path: "CODEOWNERS", data: codeowner_content) }
      let(:codeowner_blob_ref) { fake_blob(path: "CODEOWNERS", data: codeowner_content) }
      let(:codeowner_lookup_ref) { merge_request.target_branch }
      let(:merge_request) do
        build(
          :merge_request,
          source_project: project,
          source_branch: 'feature',
          target_project: project,
          target_branch: 'master'
        )
      end

      before do
        allow(project.repository).to receive(:code_owners_blob)
          .with(ref: codeowner_lookup_ref)
          .and_return(codeowner_blob)
      end

      context 'the MR contains a renamed file matching a file path' do
        let(:diff_check) { described_class.new(change_access) }
        let(:protected_branch) { build(:protected_branch, name: 'master', project: project) }

        before do
          expect(project).to receive(:branch_requires_code_owner_approval?)
            .at_least(:once).and_return(true)

          # This particular commit renames a file:
          allow(project.repository).to receive(:new_commits).and_return(
            [project.repository.commit('6907208d755b60ebeacb2e9dfea74c92c3449a1f')]
          )
        end

        it "returns an error message" do
          expect { diff_check.validate! }.to raise_error do |error|
            expect(error).to be_a(Gitlab::GitAccess::ForbiddenError)
            expect(error.message).to include("CODEOWNERS` were matched:\n- *.js.coffee")
          end
        end
      end

      context "the MR contains a matching file path" do
        let(:validation_result) do
          subject.send(:validate_code_owners).call(["docs/CODEOWNERS", "README"])
        end

        before do
          expect(project).to receive(:branch_requires_code_owner_approval?)
            .at_least(:once).and_return(true)
        end

        it_behaves_like "returns codeowners validation message"
      end

      context "the MR doesn't contain a matching file path" do
        it "returns nil" do
          expect(subject.send(:validate_code_owners)
            .call(["docs/SAFE_FILE_NAME", "README"])).to be_nil
        end
      end
    end

    describe "#file_paths_validations" do
      include_context 'change access checks context'

      context "when the feature isn't enabled on the project" do
        before do
          expect(project).to receive(:branch_requires_code_owner_approval?)
            .once.and_return(false)
        end

        it "returns an empty array" do
          expect(subject.send(:file_paths_validations)).to eq([])
        end
      end

      context "when the feature is enabled on the project" do
        context "updated_from_web? == false" do
          before do
            expect(subject).to receive(:updated_from_web?).and_return(false)
            expect(project).to receive(:branch_requires_code_owner_approval?)
              .once.and_return(true)
          end

          it "returns an array of Proc(s)" do
            validations = subject.send(:file_paths_validations)

            expect(validations.any?).to be_truthy
            expect(validations.any? { |v| !v.is_a? Proc }).to be_falsy
          end
        end

        context "updated_from_web? == true" do
          before do
            expect(subject).to receive(:updated_from_web?).and_return(true)
          end

          it "returns an empty array" do
            expect(subject.send(:file_paths_validations)).to eq([])
          end
        end
      end
    end

    context 'file name rules' do
      # Notice that the commit used creates a file named 'README'
      context 'file name regex check' do
        let!(:push_rule) { create(:push_rule, file_name_regex: 'READ*') }

        it_behaves_like 'check ignored when push rule unlicensed'

        it "returns an error if a new or renamed filed doesn't match the file name regex" do
          expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "File name README was prohibited by the pattern \"READ*\".")
        end

        it 'returns an error if the regex is invalid' do
          push_rule.file_name_regex = '+'

          expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, /\ARegular expression '\+' is invalid/)
        end
      end

      context 'blacklisted files check' do
        let(:push_rule) { create(:push_rule, prevent_secrets: true) }

        it_behaves_like 'check ignored when push rule unlicensed'

        it "returns true if there is no blacklisted files" do
          new_rev = nil

          white_listed =
            [
              'readme.txt', 'any/ida_rsa.pub', 'any/id_dsa.pub', 'any_2/id_ed25519.pub',
              'random_file.pdf', 'folder/id_ecdsa.pub', 'docs/aws/credentials.md', 'ending_withhistory'
            ]

          white_listed.each do |file_path|
            old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
            old_rev = new_rev if new_rev
            new_rev = project.repository.create_file(user, file_path, "commit #{file_path}", message: "commit #{file_path}", branch_name: "master")

            allow(project.repository).to receive(:new_commits).and_return(
              project.repository.commits_between(old_rev, new_rev)
            )

            expect(subject.validate!).to be_truthy
          end
        end

        it "returns an error if a new or renamed filed doesn't match the file name regex" do
          new_rev = nil

          black_listed =
            [
              'aws/credentials', '.ssh/personal_rsa', 'config/server_rsa', '.ssh/id_rsa', '.ssh/id_dsa',
              '.ssh/personal_dsa', 'config/server_ed25519', 'any/id_ed25519', '.ssh/personal_ecdsa', 'config/server_ecdsa',
              'any_place/id_ecdsa', 'some_pLace/file.key', 'other_PlAcE/other_file.pem', 'bye_bug.history', 'pg_sql_history'
            ]

          black_listed.each do |file_path|
            old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
            old_rev = new_rev if new_rev
            new_rev = project.repository.create_file(user, file_path, "commit #{file_path}", message: "commit #{file_path}", branch_name: "master")

            allow(subject).to receive(:commits).and_return(
              project.repository.commits_between(old_rev, new_rev)
            )

            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, /File name #{file_path} was prohibited by the pattern/)
          end
        end
      end
    end

    context 'file lock rules' do
      let_it_be(:push_rule) { create(:push_rule) }
      let_it_be(:owner) { create(:user) }

      let(:path_lock) { create(:path_lock, path: 'README', project: project) }

      before do
        project.add_developer(owner)
      end

      shared_examples 'a locked file' do
        let!(:path_lock) { create(:path_lock, path: filename, project: project, user: owner) }

        before do
          allow(project.repository).to receive(:new_commits).and_return(
            [project.repository.commit(sha)]
          )
        end

        context 'and path is locked by another user' do
          it 'returns an error' do
            path_lock

            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "The path '#{filename}' is locked by #{path_lock.user.name}")
          end
        end

        context 'and path is locked by current user' do
          let(:user) { owner }

          it 'is allows changes' do
            path_lock

            expect { subject.validate! }.not_to raise_error
          end
        end
      end

      context 'when file has changes' do
        let_it_be(:filename) { 'files/ruby/popen.rb' }
        let_it_be(:sha) { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }

        it_behaves_like 'a locked file'
      end

      context 'when file is renamed' do
        let_it_be(:filename) { 'files/js/commit.js.coffee' }
        let_it_be(:sha) { '6907208d755b60ebeacb2e9dfea74c92c3449a1f' }

        it_behaves_like 'a locked file'
      end

      context 'when file is deleted' do
        let_it_be(:filename) { 'files/js/commit.js.coffee' }
        let_it_be(:sha) { 'd59c60028b053793cecfb4022de34602e1a9218e' }

        it_behaves_like 'a locked file'
      end

      it 'memoizes the validate_path_locks? call' do
        expect(project).to receive(:any_path_locks?).once.and_call_original

        2.times { subject.validate! }
      end

      context 'when the branch is being deleted' do
        let(:newrev) { Gitlab::Git::BLANK_SHA }

        it 'does not run' do
          path_lock

          expect { subject.validate! }.not_to raise_error
        end
      end

      context 'when there is no valid change' do
        let(:changes) { { oldrev: '_any', newrev: nil, ref: nil } }

        it 'does not run' do
          path_lock

          expect { subject.validate! }.not_to raise_error
        end
      end
    end
  end
end
