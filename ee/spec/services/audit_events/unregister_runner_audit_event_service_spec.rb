# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::UnregisterRunnerAuditEventService do
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(runner, author, entity) }
  let(:common_attrs) do
    {
      author_id: -1,
      created_at: timestamp,
      id: subject.id,
      target_type: runner.class.name,
      target_id: runner.id,
      ip_address: nil,
      details: {
        target_type: runner.class.name,
        target_id: runner.id,
        ip_address: nil
      }
    }
  end

  shared_examples 'expected audit event' do
    it 'returns audit event attributes' do
      travel_to(timestamp) do
        expect(subject.attributes).to eq(attrs.stringify_keys)
      end
    end
  end

  shared_context 'when unregistering runner' do
    let(:extra_attrs) { {} }
    let(:attrs) do
      entity_class_name = entity.class.name if entity

      common_attrs.deep_merge(
        entity_id: entity&.id || -1,
        entity_type: entity ? entity_class_name : 'User',
        entity_path: entity&.full_path,
        target_details: target_details,
        details: {
          custom_message: "Unregistered #{entity_class_name&.downcase || 'instance'} CI runner",
          entity_id: entity&.id || -1,
          entity_type: entity ? entity_class_name : 'User',
          entity_path: entity&.full_path,
          target_details: target_details
        }
      ).deep_merge(extra_attrs)
    end

    context 'with authentication token author' do
      let(:author) { 'b6bce79c3a' }
      let(:extra_attrs) do
        {
          author_name: author[0...8],
          details: {
            author_name: author[0...8],
            runner_authentication_token: author[0...8]
          }
        }
      end

      it_behaves_like 'expected audit event'
    end

    context 'with User author' do
      let(:author) { user }
      let(:extra_attrs) do
        {
          author_id: author.id,
          author_name: author.name,
          details: { author_name: author.name }
        }
      end

      it_behaves_like 'expected audit event'
    end
  end

  describe '#track_event' do
    before do
      stub_licensed_features(admin_audit_log: true)
    end

    subject { service.track_event }

    let(:timestamp) { Time.zone.local(2021, 12, 28) }

    context 'for instance runner' do
      before do
        stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
      end

      let_it_be(:runner) { create(:ci_runner) }

      let(:entity) {}
      let(:extra_attrs) { {} }
      let(:target_details) { ::Gitlab::Routing.url_helpers.admin_runner_path(runner) }
      let(:attrs) do
        common_attrs.deep_merge(
          author_name: nil,
          entity_id: -1,
          entity_type: 'User',
          entity_path: nil,
          target_details: target_details,
          details: {
            custom_message: 'Unregistered instance CI runner',
            entity_path: nil,
            target_details: target_details
          }
        ).deep_merge(extra_attrs)
      end

      context 'with authentication token author' do
        let(:author) { 'b6bce79c3a' }
        let(:extra_attrs) do
          {
            details: { runner_authentication_token: author[0...8] }
          }
        end

        it_behaves_like 'expected audit event'
      end

      context 'with User author' do
        let(:author) { user }

        let(:extra_attrs) do
          { author_id: author.id }
        end

        it_behaves_like 'expected audit event'
      end
    end

    context 'for group runner' do
      let_it_be(:entity) { create(:group) }
      let_it_be(:runner) { create(:ci_runner, :group, groups: [entity]) }

      include_context 'when unregistering runner' do
        let(:extra_attrs) { {} }
        let(:target_details) { ::Gitlab::Routing.url_helpers.group_runner_path(entity, runner) }
      end
    end

    context 'for project runner' do
      let_it_be(:entity) { create(:project) }
      let_it_be(:runner) { create(:ci_runner, :project, projects: [entity]) }

      include_context 'when unregistering runner' do
        let(:extra_attrs) { {} }
        let(:target_details) { ::Gitlab::Routing.url_helpers.project_runner_path(entity, runner) }
      end
    end
  end
end
