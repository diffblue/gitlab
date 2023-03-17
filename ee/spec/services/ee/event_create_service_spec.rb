# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventCreateService, feature_category: :service_ping do
  let(:service) { described_class.new }

  describe 'Epics' do
    let(:epic) { create(:epic) }

    describe '#open_epic' do
      it "creates new event" do
        event = service.open_epic(epic, epic.author)

        expect_event(event, 'created')
      end
    end

    describe '#close_epic' do
      it "creates new event" do
        event = service.close_epic(epic, epic.author)

        expect_event(event, 'closed')
      end
    end

    describe '#reopen_epic' do
      it "creates new event" do
        event = service.reopen_epic(epic, epic.author)

        expect_event(event, 'reopened')
      end
    end

    describe '#leave_note' do
      it "creates new event" do
        note = create(:note, noteable: epic)

        event = service.leave_note(note, epic.author)

        expect_event(event, 'commented')
      end
    end

    def expect_event(event, action)
      expect(event).to be_persisted
      expect(event.action).to eq action
      expect(event.project_id).to be_nil
      expect(event.group_id).to eq epic.group_id
    end
  end
end
