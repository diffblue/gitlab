# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::Clone::CopyResourceEventsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:original_issue) { create(:issue, project: project) }

  context 'when a new object is a group entity' do
    context 'when entity is an epic' do
      let_it_be(:new_epic) { create(:epic, group: group) }

      subject { described_class.new(user, original_issue, new_epic) }

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
