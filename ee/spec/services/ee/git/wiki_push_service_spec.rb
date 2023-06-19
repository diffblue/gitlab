# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::WikiPushService, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:key_id) { create(:key, user: current_user).shell_id }
  let_it_be(:wiki) { create(:project_wiki) }
  let_it_be(:current_user) { wiki.container.first_owner }
  let_it_be(:repository) { wiki.repository }

  let(:post_received) { ::Gitlab::GitPostReceive.new(wiki.container, key_id, changes, {}) }

  before do
    allow(post_received).to receive(:identify).and_return(current_user)
  end

  describe '#process_changes' do
    context 'with a group wiki' do
      let_it_be(:wiki) { create(:group_wiki) }
      let_it_be(:changes) { +"123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag\n423423 797823 refs/heads/master" }

      it 'does not create any events' do
        expect do
          described_class.new(wiki, current_user, changes: post_received.changes).execute
        end.not_to change(Event, :count)
      end
    end
  end

  context 'when elasticsearch is enabled' do
    before do
      allow(wiki.container).to receive(:use_elasticsearch?).and_return(true)
    end

    describe 'when changes include master ref' do
      let_it_be(:changes) { +"123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag\n423423 797823 refs/heads/master" }

      before do
        allow(wiki.repository.raw).to receive(:raw_changes_between).once.with('423423', '797823').and_return([])
      end

      it 'triggers a wiki update for project' do
        expect(wiki).to receive(:index_wiki_blobs)

        described_class.new(wiki, current_user, changes: post_received.changes).execute
      end

      context 'with a group wiki', :elastic do
        let_it_be(:group) { create(:group) }
        let_it_be(:wiki) { build(:group_wiki, group: group) }

        it 'triggers a wiki update' do
          expect(wiki).to receive(:index_wiki_blobs)

          described_class.new(wiki, current_user, changes: post_received.changes).execute
        end
      end
    end

    describe 'when changes do not include master ref' do
      let_it_be(:changes) { +"123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }

      it 'does not trigger a wiki update' do
        expect(wiki).not_to receive(:index_wiki_blobs)

        described_class.new(wiki, current_user, changes: post_received.changes).execute
      end
    end
  end

  context 'when elasticsearch is disabled' do
    before do
      allow(wiki.container).to receive(:use_elasticsearch?).and_return(false)
      allow(wiki.repository.raw).to receive(:raw_changes_between).once.with('423423', '797823').and_return([])
    end

    describe 'when changes include master ref' do
      let_it_be(:changes) { +"123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag\n423423 797823 refs/heads/master" }

      it 'does nothing even if changes include master ref' do
        expect(wiki).not_to receive(:index_wiki_blobs)

        described_class.new(wiki, current_user, changes: post_received.changes).execute
      end
    end
  end
end
