# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::ConfidentialEpicService, feature_category: :team_planning do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:group_member) { create(:user) }
  let_it_be(:shared_user) { create(:user) }
  let_it_be(:group_link) { create(:group_group_link, shared_group: group) }
  let_it_be(:epic_1, reload: true) { create(:epic, :confidential, group: group, author: author) }

  let!(:todos) do
    [
      # todos not to be deleted
      create(:todo, user: group_member, target: epic_1, group: group),
      create(:todo, user: user, group: group),
      create(:todo, user: shared_user, target: epic_1, group: group),
      # Todos to be deleted
      create(:todo, user: guest, target: epic_1, group: group),
      create(:todo, user: user, target: epic_1, group: group)
    ]
  end

  describe '#execute' do
    before do
      group.add_reporter(group_member)
      group.add_guest(guest)
      group_link.shared_with_group.add_reporter(shared_user)
    end

    subject { described_class.new(epic_id: epic_1.id).execute }

    it 'removes epic todos for users who can not access the confidential epic' do
      expect { subject }.to change { Todo.count }.by(-2)
    end

    context 'when provided epic is not confidential' do
      before do
        epic_1.update!(confidential: false)
      end

      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end
  end
end
