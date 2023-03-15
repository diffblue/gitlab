# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::AllowedTargetFilterService, feature_category: :team_planning do
  let_it_be(:authorized_group) { create(:group, :private) }
  let_it_be(:authorized_project) { create(:project, group: authorized_group) }
  let_it_be(:unauthorized_group) { create(:group, :private) }
  let_it_be(:unauthorized_project) { create(:project, group: unauthorized_group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:authorized_epic) { create(:epic, group: authorized_group) }
  let_it_be(:authorized_epic_todo) { create(:todo, group: authorized_group, target: authorized_epic, user: user) }
  let_it_be(:unauthorized_epic) { create(:epic, group: unauthorized_group) }
  let_it_be(:unauthorized_epic_todo) { create(:todo, group: unauthorized_group, target: unauthorized_epic, user: user) }

  before_all do
    authorized_group.add_developer(user)
  end

  describe '#execute' do
    subject(:execute_service) { described_class.new(all_todos, user).execute }

    let!(:all_todos) { authorized_todos + unauthorized_todos }

    let(:authorized_todos) do
      [
        authorized_epic_todo
      ]
    end

    let(:unauthorized_todos) do
      [
        unauthorized_epic_todo
      ]
    end

    before do
      stub_licensed_features(epics: true)
    end

    it { is_expected.to match_array(authorized_todos) }
  end
end
