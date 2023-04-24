# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Mutations::Boards::EpicBoards::Create do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:name) { 'A glorious epic board' }

  subject { mutation.resolve(group_path: group.full_path, name: name) }

  shared_examples 'epic board creation error' do
    it 'raises error' do
      expect { mutation.resolve(group_path: group.full_path, name: name) }
        .to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'field tests' do
    subject { described_class }

    specify do
      is_expected.to have_graphql_arguments(
        :groupPath, :name, :hideBacklogList, :hideClosedList, :labels, :labelIds, :displayColors)
    end

    it { is_expected.to have_graphql_fields(:epic_board).at_least }
  end

  context 'with epic feature enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when user does not have permission to create epic board' do
      it_behaves_like 'epic board creation error'
    end

    context 'when user has permission to create epic board' do
      before do
        group.add_reporter(current_user)
      end

      it 'creates an epic board' do
        result = mutation.resolve(group_path: group.full_path, name: name)

        expect(result[:epic_board]).to be_valid
        expect(result[:epic_board].group).to eq(group)
        expect(result[:epic_board].name).to eq(name)
      end
    end
  end

  context 'with epic feature disabled' do
    before do
      stub_licensed_features(epics: false)
    end

    it_behaves_like 'epic board creation error'
  end
end
