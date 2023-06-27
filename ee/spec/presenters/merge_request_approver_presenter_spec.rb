# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestApproverPresenter do
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
  let(:file_paths) { %w{readme.md} }
  let(:approvals_required) { 10 }
  let(:enable_code_owner) { true }

  let(:author) { merge_request.author }
  let(:committer_a) { create(:user) }
  let(:committer_b) { create(:user) }
  let(:code_owner_loader) { double(:loader) }

  subject { described_class.new(merge_request) }

  before do
    allow(merge_request).to receive(:modified_paths).and_return(file_paths)
    allow(merge_request).to receive(:approvals_required).and_return(approvals_required)

    project.add_developer(committer_a)
    project.add_developer(committer_b)

    stub_licensed_features(code_owners: enable_code_owner)
  end

  def expect_code_owner_loader_init
    expect(Gitlab::CodeOwners::Loader).to receive(:new).with(
      merge_request.target_project,
      merge_request.target_branch_ref,
      file_paths
    ).and_return(code_owner_loader)

    expect(code_owner_loader).to receive(:track_file_validation).and_return(nil)
  end

  def expect_git_log_call(*stub_return_users)
    analyzer = double(:analyzer)

    expect(Gitlab::AuthorityAnalyzer).to receive(:new).with(
      merge_request,
      merge_request.author
    ).and_return(analyzer)

    expect(analyzer).to receive(:calculate).and_return(stub_return_users)
  end

  describe '#render' do
    before do
      project.add_developer(committer_a)
      project.add_developer(committer_b)
    end

    it 'displays committers' do
      expect_git_log_call(committer_a)
      expect(subject).to receive(:render_user).with(committer_a).and_call_original

      subject.render
    end

    context 'approvals_required is low' do
      let(:approvals_required) { 1 }

      it 'returns the top n committers' do
        expect_git_log_call(committer_a, committer_b)
        expect(subject).to receive(:render_user).with(committer_a).and_call_original
        expect(subject).not_to receive(:render_user).with(committer_b)

        subject.render
      end
    end
  end

  describe '#any?' do
    it 'returns true if any user exists' do
      expect_git_log_call(committer_a)

      expect(subject.any?).to eq(true)
    end

    it 'returns false if no user exists' do
      expect_git_log_call

      expect(subject.any?).to eq(false)
    end

    it 'caches loaded users' do
      expect(subject).to receive(:users_from_git_log_authors).once.and_call_original

      subject.any?
      subject.any?
    end
  end

  describe '#render_user' do
    it 'renders link' do
      result = subject.render_user(committer_a)

      expect(result).to start_with('<a')
    end
  end

  describe '#show_code_owner_tips?' do
    context 'when code_owner feature enabled and code owner is empty' do
      before do
        expect_code_owner_loader_init
        allow(code_owner_loader).to receive(:empty_code_owners?).and_return(true)
      end

      it 'returns true' do
        expect(subject.show_code_owner_tips?).to eq(true)
      end
    end

    context 'when code_owner feature enabled and code owner is not empty' do
      before do
        expect_code_owner_loader_init
        allow(code_owner_loader).to receive(:empty_code_owners?).and_return(false)
      end

      it 'returns false' do
        expect(subject.show_code_owner_tips?).to eq(false)
      end
    end

    context 'when code_owner feature is disabled' do
      let(:enable_code_owner) { false }

      it 'returns false' do
        expect(subject.show_code_owner_tips?).to eq(false)
      end
    end
  end
end
