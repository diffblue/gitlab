# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::EpicBoards::CreateService, services: true do
  def created_board
    service.execute.payload
  end

  let_it_be(:user) { create(:user) }

  let(:parent) { create(:group) }

  context 'create epic board' do
    it_behaves_like 'create a board', :epic_boards

    context 'when logged in' do
      it 'tracks epic board creation' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event).with('g_project_management_users_creating_epic_boards', values: user.id)

        described_class.new(parent, user).execute
      end
    end

    context 'when not logged in' do
      it 'tracks epic board creation' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event).with('g_project_management_users_creating_epic_boards', values: nil)

        described_class.new(parent, nil).execute
      end
    end
  end
end
