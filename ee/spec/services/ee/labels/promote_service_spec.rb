# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Labels::PromoteService, feature_category: :team_planning do
  let(:user) { create(:admin) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }

  subject(:service) { described_class.new(project, user) }

  describe '#execute' do
    it 'updates board scopes to the new promoted label' do
      project_label = create(:label, project: project)
      board = create(:board, project: project, labels: [project_label])

      new_label = service.execute(project_label)

      expect(board.reload.labels).to contain_exactly(new_label)
    end
  end
end
