# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::CommonSystemNotesService, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue) }

  RSpec.shared_examples 'issuable iteration changed' do
    context 'when iteration is changed' do
      let_it_be(:iteration) { create(:iteration) }

      before do
        issuable.update!(iteration: iteration)
      end

      it 'creates a resource iteration event' do
        subject
        event = issuable.reload.resource_iteration_events.last

        expect(event).not_to be_nil
        expect(event.iteration.id).to eq iteration.id
        expect(event.user_id).to eq user.id
      end
    end
  end

  context 'on issuable update' do
    subject { described_class.new(project: project, current_user: user).execute(issuable, old_labels: []) }

    context 'when weight is changed' do
      before do
        issuable.update!(weight: 5)
      end

      it 'creates a resource weight event' do
        subject
        event = issuable.reload.resource_weight_events.last

        expect(event).not_to be_nil
        expect(event.weight).to eq 5
        expect(event.user_id).to eq user.id
      end
    end

    context 'when health status is updated' do
      before do
        issuable.update!(health_status: 2)
      end

      context 'when setting a health_status' do
        it 'creates system note' do
          expect { subject }.to change { Note.count }.from(0).to(1)

          expect(Note.last.note).to eq('changed health status to **needs attention**')
        end
      end

      context 'when health status is removed' do
        it 'creates system note' do
          issuable.update!(health_status: nil)

          expect { subject }.to change { Note.count }.from(0).to(1)

          expect(Note.last.note).to eq("removed health status **needs attention**")
        end
      end
    end

    context 'when issuable is an epic' do
      let(:timestamp) { Time.current }
      let(:issuable) { create(:epic, end_date: timestamp) }

      subject { described_class.new(project: nil, current_user: user).execute(issuable, old_labels: []) }

      before do
        issuable.assign_attributes(start_date: timestamp, end_date: nil)
        issuable.save!
      end

      it 'creates 2 system notes with the correct content' do
        expect { subject }.to change { Note.count }.from(0).to(2)

        expect(Note.first.note).to match("changed start date to #{timestamp.strftime('%b %-d, %Y')}")
        expect(Note.second.note).to match('removed the finish date')
      end
    end

    it_behaves_like 'issuable iteration changed'
  end

  context 'on issuable create' do
    let(:issuable) { build(:issue) }

    subject { described_class.new(project: project, current_user: user).execute(issuable, old_labels: [], is_update: false) }

    before do
      issuable.update!(weight: 5, health_status: 'at_risk')
    end

    it 'creates a resource weight event' do
      expect { subject }.to change { ResourceWeightEvent.count }
    end

    it 'does not create a system note' do
      expect { subject }.not_to change { Note.count }
    end

    it_behaves_like 'issuable iteration changed'
  end
end
