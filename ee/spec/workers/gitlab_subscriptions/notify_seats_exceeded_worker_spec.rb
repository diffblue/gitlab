# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::NotifySeatsExceededWorker do
  describe '#handle_event' do
    let_it_be(:group) { create(:group) }

    context 'when the event source is unrecognized' do
      it 'does not call the notification service' do
        namespace = create(:namespace)

        event = Members::MembersAddedEvent.new(data: {
          source_id: namespace.id,
          source_type: 'Namespace'
        })

        expect(GitlabSubscriptions::NotifySeatsExceededService).not_to receive(:new)

        expect(described_class.new.handle_event(event)).to be_nil
      end
    end

    context 'when the event source is a project' do
      it 'calls the service with the root ancestor group' do
        project = create(:project, namespace: group)

        event = Members::MembersAddedEvent.new(data: {
          source_id: project.id,
          source_type: 'Project'
        })

        expect(GitlabSubscriptions::NotifySeatsExceededService)
          .to receive(:new)
          .with(group)
          .and_call_original

        described_class.new.handle_event(event)
      end
    end

    context 'when the project cannot be found' do
      it 'returns nil without calling the notification service' do
        event = Members::MembersAddedEvent.new(data: {
          source_id: 0,
          source_type: 'Project'
        })

        expect(GitlabSubscriptions::NotifySeatsExceededService).not_to receive(:new)

        expect(described_class.new.handle_event(event)).to be_nil
      end
    end

    context 'when the group cannot be found' do
      it 'returns nil without calling the notification service' do
        event = Members::MembersAddedEvent.new(data: {
          source_id: 0,
          source_type: group.class.name
        })

        expect(GitlabSubscriptions::NotifySeatsExceededService).not_to receive(:new)

        expect(described_class.new.handle_event(event)).to be_nil
      end
    end

    context 'when supplied valid group data' do
      it 'calls the notification service' do
        event = Members::MembersAddedEvent.new(data: {
          source_id: group.id,
          source_type: group.class.name
        })

        expect(GitlabSubscriptions::NotifySeatsExceededService)
          .to receive(:new)
          .with(group)
          .and_call_original

        described_class.new.handle_event(event)
      end
    end

    context 'when the group is a subgroup' do
      it 'calls the notification service with the root ancestor' do
        child_group = create(:group, parent: group)

        event = Members::MembersAddedEvent.new(data: {
          source_id: child_group.id,
          source_type: child_group.class.name
        })

        expect(GitlabSubscriptions::NotifySeatsExceededService)
          .to receive(:new)
          .with(group)
          .and_call_original

        described_class.new.handle_event(event)
      end
    end
  end
end
