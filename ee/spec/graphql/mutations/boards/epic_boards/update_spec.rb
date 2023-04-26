# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Mutations::Boards::EpicBoards::Update do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:epic_board, group: group) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  subject { mutation.resolve(id: board.to_global_id) }

  shared_examples 'epic board update error' do
    it 'raises error' do
      expect { subject }
        .to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'field tests' do
    subject { described_class }

    specify do
      is_expected.to have_graphql_arguments(
        :id, :name, :hideBacklogList, :hideClosedList, :labels, :labelIds, :displayColors)
    end

    it { is_expected.to have_graphql_fields(:epic_board).at_least }
  end

  context 'with epic feature enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when user does not have permission to update epic board' do
      it_behaves_like 'epic board update error'
    end

    context 'when user has permission to update epic board' do
      before do
        group.add_reporter(current_user)
      end

      it 'updates the epic board' do
        result = mutation.resolve(id: board.to_global_id, name: 'new name', hide_backlog_list: true)

        expect(result[:errors]).to be_empty
        expect(result[:epic_board].name).to eq('new name')
        expect(result[:epic_board].hide_backlog_list).to be_truthy
      end
    end
  end

  describe '#ready?' do
    it 'raises an error when both labels and label_ids arguments are passed' do
      label = create(:group_label)

      expect do
        mutation.ready?(id: board.to_global_id, labels: ['foo'], label_ids: [label.to_global_id.to_s])
      end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, /one and only one of labels or labelIds is required/)
    end
  end
end
