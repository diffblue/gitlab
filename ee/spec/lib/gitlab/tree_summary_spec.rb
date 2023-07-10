# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TreeSummary do
  let_it_be_with_refind(:project) { create(:project, :custom_repo, files: { 'a.txt' => '' }) }
  let_it_be(:path_lock) { create(:path_lock, project: project, path: 'a.txt') }
  let_it_be(:user) { create(:user) }

  let(:commit) { project.repository.head_commit }

  subject { described_class.new(commit, project, user).summarize }

  describe '#summarize (entries)' do
    it 'includes path locks in entries' do
      is_expected.to contain_exactly(
        a_hash_including(file_name: 'a.txt', lock_label: "Locked by #{path_lock.user.username}")
      )
    end
  end

  context 'when file_locks feature is unavailable' do
    before do
      stub_licensed_features(file_locks: false)
    end

    it 'does not fill lock labels' do
      expect(subject.first.keys).not_to include(:lock_label)
    end
  end
end
