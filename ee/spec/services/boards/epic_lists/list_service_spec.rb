# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::EpicLists::ListService do
  let(:user) { create(:user) }

  describe '#execute' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:label) { create(:group_label, group: parent) }
    let_it_be(:unrelated_list) { create(:epic_list) }
    let_it_be_with_reload(:board) { create(:epic_board, group: parent) }
    let_it_be(:list) { create(:epic_list, epic_board: board, label: label) }
    let_it_be(:closed_list) { create(:epic_list, epic_board: board, list_type: :closed) }
    let_it_be(:backlog_list) { create(:epic_list, epic_board: board, list_type: :backlog) }

    let(:service) { described_class.new(parent, user) }

    it_behaves_like 'lists list service'
  end
end
