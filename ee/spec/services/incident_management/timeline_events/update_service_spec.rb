# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvents::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let!(:timeline_event) { create(:incident_management_timeline_event, project: project, incident: incident) }
  let(:occurred_at) { 1.minute.ago }
  let(:params) { { note: 'Updated note', occurred_at: occurred_at } }

  before do
    stub_licensed_features(incident_timeline_events: true)
  end

  describe '#execute' do
    shared_examples 'successful response' do
      it 'responds with success', :aggregate_failures do
        expect(execute).to be_success
        expect(execute.payload).to eq(timeline_event: timeline_event.reload)
      end
    end

    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    subject(:execute) { described_class.new(timeline_event, user, params).execute }

    context 'when user has permissions' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'successful response'

      it 'updates attributes' do
        expect { execute }.to change { timeline_event.note }.to(params[:note])
          .and change { timeline_event.occurred_at }.to(params[:occurred_at])
      end

      context 'when note is nil' do
        let(:params) { { occurred_at: occurred_at } }

        it_behaves_like 'successful response'

        it 'does not update the note' do
          expect { execute }.not_to change { timeline_event.reload.note }
        end

        it 'updates occurred_at' do
          expect { execute }.to change { timeline_event.occurred_at }.to(params[:occurred_at])
        end
      end

      context 'when note is blank' do
        let(:params) { { note: '', occurred_at: occurred_at } }

        it_behaves_like 'successful response'

        it 'does not update the note' do
          expect { execute }.not_to change { timeline_event.reload.note }
        end

        it 'updates occurred_at' do
          expect { execute }.to change { timeline_event.occurred_at }.to(params[:occurred_at])
        end
      end

      context 'when occurred_at is nil' do
        let(:params) { { note: 'Updated note' } }

        it_behaves_like 'successful response'

        it 'updates the note' do
          expect { execute }.to change { timeline_event.note }.to(params[:note])
        end

        it 'does not update occurred_at' do
          expect { execute }.not_to change { timeline_event.reload.occurred_at }
        end
      end
    end

    context 'when user does not have permissions' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when licensed feature is not available' do
      before do
        stub_licensed_features(incident_timeline_events: false)
      end

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end
  end
end
