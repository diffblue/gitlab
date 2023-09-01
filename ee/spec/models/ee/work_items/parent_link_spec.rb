# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::WorkItems::ParentLink, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe 'validations' do
    describe 'validate_hierarchy_restrictions' do
      context 'when assigning a parent with type Epic' do
        let_it_be_with_reload(:issue) { create(:work_item, project: project) }
        let_it_be(:legacy_epic) { create(:epic, group: group) }
        let_it_be(:epic) { create(:work_item, :epic, project: project) }

        subject { described_class.new(work_item: issue, work_item_parent: epic) }

        it 'is valid for child with no legacy epic' do
          expect(subject).to be_valid
        end

        it 'is invalid for child with existing legacy epic', :aggregate_failures do
          create(:epic_issue, epic: legacy_epic, issue: issue)

          expect(subject).to be_invalid
          expect(subject.errors.full_messages).to include('Work item already assigned to an epic')
        end
      end
    end
  end
end
