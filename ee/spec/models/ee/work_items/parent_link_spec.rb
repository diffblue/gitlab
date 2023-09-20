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

      context 'when assigning parent from a different resource parent' do
        let_it_be(:issue) { create(:work_item, :issue, project: project) }
        let_it_be(:epic) { create(:work_item, :epic, namespace: create(:group)) }

        let(:restriction) do
          WorkItems::HierarchyRestriction
            .find_by_parent_type_id_and_child_type_id(epic.work_item_type_id, issue.work_item_type_id)
        end

        it 'is valid when cross-hierarchy is enabled' do
          restriction.update!(cross_hierarchy_enabled: true)
          link = build(:parent_link, work_item_parent: epic, work_item: issue)

          expect(link).to be_valid
          expect(link.errors).to be_empty
        end

        it 'is not valid when cross-hierarchy is not enabled' do
          restriction.update!(cross_hierarchy_enabled: false)
          link = build(:parent_link, work_item_parent: epic, work_item: issue)

          expect(link).not_to be_valid
          expect(link.errors[:work_item_parent]).to include('parent must be in the same project or group as child.')
        end
      end
    end
  end
end
