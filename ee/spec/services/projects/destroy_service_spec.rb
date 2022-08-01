# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DestroyService do
  include EE::GeoHelpers

  let!(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let!(:project_id) { project.id }
  let!(:project_name) { project.name }
  let!(:project_path) { project.disk_path }
  let!(:wiki_path) { project.wiki.disk_path }
  let!(:storage_name) { project.repository_storage }

  subject { described_class.new(project, user, {}) }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  context 'when project is a mirror' do
    let(:max_capacity) { Gitlab::CurrentSettings.mirror_max_capacity }
    let_it_be(:project_mirror) { create(:project, :mirror, :repository, :import_scheduled) }

    let(:result) { described_class.new(project_mirror, project_mirror.first_owner, {}).execute }

    before do
      Gitlab::Mirror.increment_capacity(project_mirror.id)
    end

    it 'decrements capacity if mirror was scheduled' do
      expect { result }.to change { Gitlab::Mirror.available_capacity }.from(max_capacity - 1).to(max_capacity)
    end
  end

  context 'when running on a primary node' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(primary)
    end

    it 'logs an event to the Geo event log' do
      # Run Sidekiq immediately to check that renamed repository will be removed
      Sidekiq::Testing.inline! do
        expect(subject).to receive(:log_destroy_events).and_call_original
        expect { subject.execute }.to change(Geo::RepositoryDeletedEvent, :count).by(1)
      end
    end

    it 'does not log event to the Geo log if project deletion fails' do
      expect(subject).to receive(:log_destroy_event).and_call_original
      expect(project).to receive(:destroy!).and_raise(StandardError.new('Other error message'))

      Sidekiq::Testing.inline! do
        expect { subject.execute }.not_to change(Geo::RepositoryDeletedEvent, :count)
      end
    end
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { subject.execute }

      let(:fail_condition!) do
        expect(project).to receive(:destroy!).and_raise(StandardError.new('Other error message'))
      end

      let(:attributes) do
        {
          author_id: user.id,
          entity_id: project.id,
          entity_type: 'Project',
          details: {
            remove: 'project',
            author_name: user.name,
            target_id: project.id,
            target_type: 'Project',
            target_details: project.full_path
          }
        }
      end
    end
  end

  context 'streaming audit event' do
    let(:group) { create :group }
    let(:project) { create :project, namespace: group }

    subject { described_class.new(project, user, {}).execute }

    before do
      group.add_owner(user)
      stub_licensed_features(external_audit_events: true)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    it 'sends the audit streaming event with json format' do
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
        'audit_operation',
        nil,
        a_string_including("root_group_entity_id\":#{group.id}"))

      subject
    end
  end

  context 'system hooks exception' do
    before do
      allow_any_instance_of(SystemHooksService).to receive(:execute_hooks_for).and_raise('something went wrong')
    end

    it 'logs an audit event' do
      expect(subject).to receive(:log_destroy_event).and_call_original
      expect { subject.execute }.to change(AuditEvent, :count)
    end
  end

  context 'when project has an associated ProjectNamespace' do
    let!(:project_namespace) { project.project_namespace }

    it 'destroys the associated ProjectNamespace also' do
      subject.execute

      expect { project_namespace.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
