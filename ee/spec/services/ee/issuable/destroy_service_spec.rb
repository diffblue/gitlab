# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::DestroyService do
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(project: nil, current_user: user) }

  describe '#execute' do
    context 'when destroying an epic' do
      let_it_be(:issuable) { create(:epic) }

      let(:group) { issuable.group }

      it 'records usage ping epic destroy event' do
        expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_destroyed)
          .with(author: user, namespace: group)

        subject.execute(issuable)
      end

      it_behaves_like 'service deleting todos'
      it_behaves_like 'service deleting label links'
    end

    context 'when destroying other issuable type' do
      let(:issuable) { create(:issue) }

      it 'does not track usage ping epic destroy event' do
        expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_destroyed)

        subject.execute(issuable)
      end
    end
  end
end
