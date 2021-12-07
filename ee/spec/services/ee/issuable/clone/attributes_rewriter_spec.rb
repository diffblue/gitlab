# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::Clone::AttributesRewriter do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:original_issue) { create(:issue, project: project) }

  context 'when a new object is a group entity' do
    context 'when entity is an epic' do
      let(:new_epic) { create(:epic, group: group) }

      subject { described_class.new(user, original_issue, new_epic) }

      context 'setting labels' do
        let(:project_label1) { create(:label, title: 'label1', project: project) }
        let!(:project_label2) { create(:label, title: 'label2', project: project) }
        let(:group_label1) { create(:group_label, title: 'group_label', group: group) }
        let!(:group_label2) { create(:group_label, title: 'label2', group: group) }

        it 'keeps group labels and merges project labels where possible' do
          original_issue.update!(labels: [project_label1, project_label2, group_label1])

          subject.execute

          expect(new_epic.reload.labels).to match_array([group_label1, group_label2])
        end
      end

      context 'setting milestones' do
        it 'ignores milestone attribute' do
          milestone = create(:milestone, title: 'milestone', group: group)
          original_issue.update!(milestone: milestone)

          expect(new_epic).to receive(:update).with(labels: [])

          subject.execute
        end
      end

      context 'when cloning state events' do
        before do
          create(:resource_state_event, issue: original_issue)
        end

        it 'ignores issue_id attribute' do
          milestone = create(:milestone, title: 'milestone', group: group)
          original_issue.update!(milestone: milestone)

          subject.execute

          latest_state_event = ResourceStateEvent.last
          expect(latest_state_event).to be_valid
          expect(latest_state_event.issue_id).to be_nil
          expect(latest_state_event.epic).to eq(new_epic)
        end
      end

      context 'when issue has weight events' do
        it 'ignores copying weight events' do
          create_list(:resource_weight_event, 2, issue: original_issue)

          expect(subject).not_to receive(:copy_events).with(ResourceWeightEvent.table_name, any_args)

          expect { subject.execute }.not_to change { ResourceWeightEvent.count }
        end
      end
    end
  end
end
