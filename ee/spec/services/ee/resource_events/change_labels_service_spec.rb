# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeLabelsService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:labels) { create_list(:group_label, 2, group: group) }

  let(:resource) { create(:epic, group: group) }

  describe '.execute' do
    subject { described_class.new(resource, user).execute(added_labels: added, removed_labels: removed) }

    context 'when adding a label' do
      let(:added)   { [labels[0]] }
      let(:removed) { [] }

      it 'tracks the label change' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
          .to receive(:track_epic_labels_changed_action).with(author: user, namespace: group)

        subject
      end
    end

    context 'when removing a label' do
      let(:added)   { [] }
      let(:removed) { [labels[1]] }

      it 'tracks the label change' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
          .to receive(:track_epic_labels_changed_action).with(author: user, namespace: group)

        subject
      end
    end

    context 'when both adding and removing labels' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      it 'tracks the label change' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
          .to receive(:track_epic_labels_changed_action).with(author: user, namespace: group)

        subject
      end
    end
  end
end
