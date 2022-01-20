# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::AuditEventStreamingWorker do
  let(:worker) { described_class.new }

  before do
    stub_licensed_features(external_audit_events: true)
  end

  shared_examples 'a successful audit event stream' do
    subject { worker.perform(event.id) }

    context 'when the group has no destinations' do
      it 'makes no HTTP calls' do
        expect(Gitlab::HTTP).not_to receive(:post)

        subject
      end
    end

    context 'when the group has a destination' do
      before do
        group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
      end

      it 'makes one HTTP call' do
        expect(Gitlab::HTTP).to receive(:post).once

        subject
      end

      it 'sends the correct verification header' do
        expect(Gitlab::HTTP).to receive(:post).with(an_instance_of(String), a_hash_including(headers: { 'X-Gitlab-Event-Streaming-Token' => anything })).once

        subject
      end
    end

    context 'when the group has several destinations' do
      before do
        group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
        group.external_audit_event_destinations.create!(destination_url: 'http://example1.com')
        group.external_audit_event_destinations.create!(destination_url: 'http://example.org')
      end

      it 'makes the correct number of HTTP calls' do
        expect(Gitlab::HTTP).to receive(:post).exactly(3).times

        subject
      end

      context 'when feature is disabled' do
        before do
          stub_feature_flags(ff_external_audit_events_namespace: false)
        end

        it 'makes no HTTP calls' do
          expect(Gitlab::HTTP).not_to receive(:post)

          subject
        end
      end

      context 'when feature is unlicensed' do
        before do
          stub_licensed_features(external_audit_events: false)
        end

        it 'makes no HTTP calls' do
          expect(Gitlab::HTTP).not_to receive(:post)

          subject
        end
      end
    end
  end

  describe "#perform" do
    context 'when the entity type is a group' do
      it_behaves_like 'a successful audit event stream' do
        let_it_be(:event) { create(:audit_event, :group_event) }

        let(:group) { event.entity }
      end
    end

    context 'when the entity type is a project that belongs to a group' do
      it_behaves_like 'a successful audit event stream' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:event) { create(:audit_event, :project_event, target_project: project) }
      end
    end

    context 'when the entity type is a project at a root namespace level' do
      let_it_be(:event) { create(:audit_event, :project_event) }

      it 'makes no HTTP calls' do
        expect(Gitlab::HTTP).not_to receive(:post)

        worker.perform(event.id)
      end
    end

    context 'when the entity is a NullEntity' do
      let_it_be(:event) { create(:audit_event, :project_event) }

      before do
        event.entity_id = non_existing_record_id
      end

      it 'makes no HTTP calls' do
        expect(Gitlab::HTTP).not_to receive(:post)

        worker.perform(event.id)
      end
    end
  end
end
