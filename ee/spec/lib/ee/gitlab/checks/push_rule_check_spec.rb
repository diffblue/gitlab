# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Checks::PushRuleCheck, feature_category: :source_code_management do
  include_context 'changes access checks context'

  let(:push_rule) { create(:push_rule, :commit_message) }
  let(:project) { create(:project, :public, :repository, push_rule: push_rule) }

  before do
    allow(project.repository).to receive(:new_commits).and_return(
      project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
    )
  end

  shared_examples "push checks" do
    before do
      allow_any_instance_of(EE::Gitlab::Checks::PushRules::FileSizeCheck)
        .to receive(:validate!).and_return(nil)
      allow_any_instance_of(EE::Gitlab::Checks::PushRules::TagCheck)
        .to receive(:validate!).and_return(nil)
      allow_any_instance_of(EE::Gitlab::Checks::PushRules::BranchCheck)
        .to receive(:validate!).and_return(nil)
    end

    it_behaves_like 'use predefined push rules'

    it "returns nil on success" do
      expect(subject.validate!).to be_nil
    end

    it "raises an error on failure" do
      expect_any_instance_of(EE::Gitlab::Checks::PushRules::FileSizeCheck).to receive(:validate!).and_raise(Gitlab::GitAccess::ForbiddenError)

      expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError)
    end

    context 'when tag name exists' do
      let(:changes) do
        [
          # Update of a tag.
          { oldrev: oldrev, newrev: newrev, ref: 'refs/tags/name' }
        ]
      end

      it 'validates tags push rules' do
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::TagCheck)
          .to receive(:validate!)
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::BranchCheck)
          .not_to receive(:validate!)

        subject.validate!
      end
    end

    context 'when branch name exists' do
      let(:changes) do
        [
          # Update of a branch.
          { oldrev: oldrev, newrev: newrev, ref: 'refs/heads/name' }
        ]
      end

      it 'validates branches push rules' do
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::TagCheck)
          .not_to receive(:validate!)
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::BranchCheck)
          .to receive(:validate!)

        subject.validate!
      end
    end

    context 'when changes are from notes ref' do
      let(:changes) do
        [{ oldrev: oldrev, newrev: newrev, ref: 'refs/notes/commits' }]
      end

      it 'does not validate push rules for tags or branches' do
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::TagCheck).not_to receive(:validate!)
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::BranchCheck).not_to receive(:validate!)

        subject.validate!
      end
    end

    context 'when tag and branch exist' do
      let(:changes) do
        [
          { oldrev: oldrev, newrev: newrev, ref: 'refs/heads/name' },
          { oldrev: oldrev, newrev: newrev, ref: 'refs/tags/name' }
        ]
      end

      it 'validates tag and branch push rules' do
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::TagCheck)
          .to receive(:validate!)
        expect_any_instance_of(EE::Gitlab::Checks::PushRules::BranchCheck)
          .to receive(:validate!)

        subject.validate!
      end
    end
  end

  describe '#validate!' do
    context "parallel push checks" do
      it_behaves_like "push checks"

      before do
        ::Gitlab::Git::HookEnv.set(project.repository.gl_repository,
                                   "GIT_OBJECT_DIRECTORY_RELATIVE" => "objects",
                                   "GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE" => [])
      end

      it "sets the git env correctly for all hooks", :request_store do
        expect(Gitaly::Repository).to receive(:new)
                                        .at_least(:once)
                                        .with(a_hash_including(git_object_directory: "objects"))
                                        .and_call_original

        # This push fails because of the commit message check
        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError)
      end
    end

    context ":parallel_push_checks feature is disabled" do
      before do
        stub_feature_flags(parallel_push_checks: false)
      end

      it_behaves_like "push checks"
    end
  end
end
