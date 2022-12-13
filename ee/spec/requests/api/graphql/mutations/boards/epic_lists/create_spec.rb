# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a label or backlog board list', feature_category: :portfolio_management do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:epic_board, group: group) }

  before do
    stub_licensed_features(epics: true)
  end

  it_behaves_like 'board lists create request' do
    let(:mutation_name) { :epic_board_list_create }
  end
end
