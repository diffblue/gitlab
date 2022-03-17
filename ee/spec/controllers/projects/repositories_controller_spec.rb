# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::RepositoriesController do
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }

  describe "GET archive" do
    subject(:get_archive) do
      get :archive, params: { namespace_id: project.namespace, project_id: project, id: "master" }, format: "zip"
    end

    def set_group_destination
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
      stub_licensed_features(external_audit_events: true)
    end

    shared_examples 'logs the audit event' do
      it 'logs the audit event' do
        expect { get_archive }.to change { AuditEvent.count }.by(1)
      end
    end

    context 'when unauthenticated', 'for a public project' do
      it_behaves_like 'logs the audit event' do
        let(:project) { create(:project, :repository, :public) }
      end

      context 'when group sets event destination' do
        before do
          set_group_destination
        end
        it "doesn't send the streaming audit event" do
          expect(AuditEvents::AuditEventStreamingWorker).not_to receive(:perform_async)
          get_archive
        end
      end
    end

    context 'when authenticated', 'as a developer' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      it_behaves_like 'logs the audit event' do
        let(:user) { create(:user) }
      end

      context 'when group sets event destination' do
        let(:user) { create(:user) }

        before do
          set_group_destination
        end
        it "sends the streaming audit event" do
          expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
          get_archive
        end
      end
    end
  end
end
