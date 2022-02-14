# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::TimelineEvent::Create do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let(:args) { { note: 'note', occurred_at: Time.current } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_incident_management_timeline_event) }

  before do
    stub_licensed_features(incident_timeline_events: true)
  end

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(incident_id: incident.to_global_id, **args) }

    context 'when a user has permissions to create a timeline event' do
      before do
        project.add_developer(current_user)
      end

      context 'when TimelineEvents::CreateService responds with success' do
        it 'adds timeline event to database' do
          expect { resolve }.to change(IncidentManagement::TimelineEvent, :count).by(1)
        end
      end

      context 'when TimelineEvents::CreateService responds with an error' do
        let(:args) { {} }

        it 'returns errors' do
          expect(resolve).to eq(timeline_event: nil, errors: ["Occurred at can't be blank, Note can't be blank, and Note html can't be blank"])
        end
      end
    end

    context 'when a user has no permissions to create timeline event' do
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
