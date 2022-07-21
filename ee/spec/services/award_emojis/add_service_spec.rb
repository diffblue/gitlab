# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::AddService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:awardable) { create(:note_on_issue, project: project) }

  let(:name) { 'thumbsup' }

  let(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    subject(:execute) { service.execute }

    describe 'publish to status page' do
      let(:issue_id) { awardable.noteable_id }

      context 'when adding succeeds' do
        context 'with recognized emoji' do
          let(:name) { Gitlab::StatusPage::AWARD_EMOJI }

          include_examples 'trigger status page publish'
        end

        context 'with unrecognized emoji' do
          let(:name) { 'x' }

          include_examples 'no trigger status page publish'
        end
      end

      context 'when adding fails' do
        let(:name) { '' }

        include_examples 'no trigger status page publish'
      end
    end

    describe 'tracking emoji adding' do
      context 'for epics' do
        let_it_be(:awardable) { create(:epic, group: group) }

        before do
          stub_licensed_features(epics: true)
          group.add_developer(user)
        end

        it 'tracks usage' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_emoji_awarded_action)
            .with(author: user, namespace: group)

          described_class.new(awardable, name, user).execute
        end
      end

      context 'for awardables that are not epics' do
        it 'does not track epic emoji awarding' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_emoji_awarded_action)

          execute
        end
      end
    end
  end
end
