# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::TimelineEvent::PromoteFromNote do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:comment) { create(:note, project: project, noteable: incident) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:issue_comment) { create(:note, project: project, noteable: issue) }

  let(:args) { { note_id: comment.to_global_id.to_s } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_incident_management_timeline_event) }

  before do
    stub_licensed_features(incident_timeline_events: true)
  end

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(**args) }

    context 'when a user has permissions to create timeline event' do
      before do
        project.add_developer(current_user)
      end

      it 'creates a timeline event' do
        expect { resolve }.to change(IncidentManagement::TimelineEvent, :count).by(1)
      end

      it 'responds with a timeline event', :aggregate_failures do
        response = resolve
        timeline_event = IncidentManagement::TimelineEvent.last!

        expect(response).to match(timeline_event: timeline_event, errors: be_empty)
        expect(timeline_event.promoted_from_note).to eq(comment)
        expect(timeline_event.note).to eq(comment.note)
        expect(timeline_event.occurred_at.to_s).to eq(comment.created_at.to_s)
        expect(timeline_event.incident).to eq(incident)
        expect(timeline_event.author).to eq(current_user)
      end

      context 'when TimelineEvents::CreateService responds with an error' do
        before do
          allow_next_instance_of(::IncidentManagement::TimelineEvents::CreateService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(payload: { timeline_event: nil }, message: 'Some error')
            )
          end
        end

        it 'returns errors' do
          expect(resolve).to eq(timeline_event: nil, errors: ['Some error'])
        end
      end
    end

    context 'when note does not exist' do
      let(:args) { { note_id: 'gid://gitlab/Note/0' } }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when note does not belong to an incident' do
      let(:args) { { note_id: issue_comment.to_global_id.to_s } }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when a user does not have permissions to create timeline event' do
      before do
        project.add_guest(current_user)
      end

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when timeline event feature is not available' do
      before do
        stub_licensed_features(incident_timeline_events: false)
      end

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  private

  def mutation_for(project, user)
    described_class.new(object: project, context: { current_user: user }, field: nil)
  end
end
