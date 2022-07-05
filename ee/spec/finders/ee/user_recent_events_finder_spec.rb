# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserRecentEventsFinder do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:epic) { create(:epic) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:private_epic) { create(:epic, group: create(:group, :private)) }
    let_it_be(:note) { create(:note_on_epic, noteable: epic) }
    let_it_be(:public_event) { create(:event, :commented, target: note, author: user1, project: nil) }
    let_it_be(:private_epic_event1) { create(:event, :closed, target: private_epic, author: user1, project: nil) }

    let(:event_filter) { nil }
    let(:target_users) { user1 }

    subject { described_class.new(current_user, target_users, event_filter, {}).execute }

    context 'epic related activities' do
      context 'when profile is public' do
        it { is_expected.to match_array([public_event, private_epic_event1]) }
      end

      context 'when profile is private' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, user1).and_return(false)
        end

        it { is_expected.to be_empty }
      end

      context 'wehen fetching events from multiple users' do
        let_it_be(:private_issue_event) { create(:event, :created, target: issue, author: user1, project: nil) }
        let_it_be(:private_epic_event2) do
          create(:event, :created, target: private_epic, author: user2, project: nil)
        end

        let_it_be(:private_epic_event3) do
          create(:event, :reopened, target: private_epic, author: user2, project: nil)
        end

        let(:event_filter) { EventFilter.new(EventFilter::EPIC) }
        let(:target_users) { [user1, user2] }

        context 'when filtering for epic events' do
          it { is_expected.to eq([private_epic_event3, private_epic_event2, private_epic_event1]) }
        end
      end
    end
  end
end
