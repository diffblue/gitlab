# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:awardable) { create(:note_on_issue, project: project) }

  let(:name) { 'thumbsup' }

  let(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    subject(:execute) { service.execute }

    before do
      create(:award_emoji, user: user, name: name, awardable: awardable)
    end

    describe 'publish to status page' do
      let(:issue_id) { awardable.noteable_id }

      context 'with recognized emoji' do
        let(:name) { Gitlab::StatusPage::AWARD_EMOJI }

        include_examples 'trigger status page publish'
      end

      context 'with unrecognized emoji' do
        let(:name) { 'x' }

        include_examples 'no trigger status page publish'
      end
    end

    describe 'tracking emoji removing' do
      context 'when awardable is an epic' do
        let_it_be(:awardable) { create(:epic, group: group) }

        before do
          stub_licensed_features(epics: true)
          group.add_developer(user)
        end

        it 'tracks usage' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_emoji_removed_action)
            .with(author: user, namespace: group)

          execute
        end
      end

      context 'when awardable is not an epic' do
        it 'does not track epic emoji awarding' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_emoji_removed_action)

          execute
        end
      end
    end
  end
end
