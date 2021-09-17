# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::CreateService, services: true do
  def created_board
    service.execute.payload
  end

  shared_examples 'boards create service' do
    context 'With the feature available' do
      before do
        stub_licensed_features(multiple_group_issue_boards: true)
      end

      it_behaves_like 'create a board', :boards
    end
  end

  describe '#execute' do
    it_behaves_like 'boards create service' do
      let(:parent) { create(:project, :empty_repo) }
    end

    it_behaves_like 'boards create service' do
      let(:parent) { create(:group) }

      it 'skips creating a second board when the feature is not available' do
        stub_licensed_features(multiple_group_issue_boards: false)
        service = described_class.new(parent, double)

        expect(service.execute.payload).not_to be_nil
        expect { service.execute }.not_to change(parent.boards, :count)
      end
    end

    context 'when setting a timebox' do
      let_it_be(:user) { create(:user) }

      before do
        parent.add_reporter(user)
      end

      subject { described_class.new(parent, user, args).execute.payload }

      it_behaves_like 'setting a milestone scope' do
        let(:args) { { milestone_id: milestone.id } }
      end

      it_behaves_like 'setting an iteration scope' do
        let(:args) { { iteration_id: iteration.id } }
      end
    end
  end
end
