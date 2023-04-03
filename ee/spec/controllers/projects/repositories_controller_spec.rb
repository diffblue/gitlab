# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::RepositoriesController, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }

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
        expect(AuditEvent.last.details).to include({
          author_name: user_name,
          custom_message: "Repository Download Started",
          target_id: project.id,
          target_type: "Project"
        })
      end
    end

    shared_examples 'sends the streaming audit event' do
      it 'sends the streaming event with audit event type' do
        expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
          event_type,
          nil,
          a_string_including("author_name\":\"#{user_name}", "custom_message\":\"Repository Download Started")
        )

        get_archive
      end
    end

    context 'when unauthenticated', 'for a public project' do
      it_behaves_like 'logs the audit event' do
        let_it_be(:project) { create(:project, :repository, :public) }
        let_it_be(:user_name) { "An unauthenticated user" }
      end

      context 'when group sets event destination' do
        before do
          set_group_destination
        end

        it_behaves_like 'sends the streaming audit event' do
          let_it_be(:project) { create(:project, :repository, :public, namespace: group) }
          let_it_be(:event_type) { "repository_download_operation" }
          let_it_be(:user_name) { "An unauthenticated user" }
        end
      end
    end

    context 'when authenticated', 'as a developer' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      it_behaves_like 'logs the audit event' do
        let_it_be(:user) { create(:user) }
        let_it_be(:user_name) { user.name }
      end

      context 'when group sets event destination' do
        let_it_be(:user) { create(:user) }

        before do
          set_group_destination
        end

        it_behaves_like 'sends the streaming audit event' do
          let(:event_type) { "repository_download_operation" }
          let_it_be(:user_name) { user.name }
        end
      end
    end
  end
end
