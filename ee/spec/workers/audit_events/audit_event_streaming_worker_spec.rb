# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::AuditEventStreamingWorker do
  let(:worker) { described_class.new }

  before do
    stub_licensed_features(external_audit_events: true)
  end

  shared_context 'a successful audit event stream' do
    context 'when audit event id is passed' do
      subject { worker.perform(audit_operation, event.id) }

      include_context 'audit event stream'
    end

    context 'when audit event json is passed' do
      subject { worker.perform(audit_operation, nil, event.to_json) }

      include_context 'audit event stream'
    end
  end

  shared_context 'a error is raised' do
    context 'when audit event id is passed' do
      subject { worker.perform('audit_operation', event.id) }

      include_context 'http post error'
    end

    context 'when audit event json is passed' do
      subject { worker.perform('audit_operation', nil, event.to_json) }

      include_context 'http post error'
    end

    context 'when both audit event id and audit event json is passed' do
      subject { worker.perform('audit_operation', event.id, event.to_json) }

      it 'a argument error is raised' do
        expect { subject }.to raise_error(ArgumentError, 'audit_event_id and audit_event_json cannot be passed together')
      end
    end
  end

  shared_context 'audit event stream' do
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
        headers = if audit_operation.present?
                    { "X-Gitlab-Audit-Event-Type" => "audit_operation", 'X-Gitlab-Event-Streaming-Token' => anything }
                  else
                    { 'X-Gitlab-Event-Streaming-Token' => anything }
                  end

        expect(Gitlab::HTTP).to receive(:post).with(an_instance_of(String), a_hash_including(headers: headers)).once

        subject
      end

      context 'sends correct event type in request body' do
        it 'adds event type only when audit operation is present' do
          if audit_operation.present?
            expect(Gitlab::HTTP).to receive(:post).with(an_instance_of(String),
                                                        hash_including(body: a_string_including("\"event_type\":\"#{audit_operation}\"")))
          else
            expect(Gitlab::HTTP).to receive(:post).with(an_instance_of(String),
                                                        hash_excluding(body: a_string_including("event_type")))
          end

          subject
        end
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

  shared_context 'http post error' do
    context 'when any of Gitlab::HTTP::HTTP_ERRORS is raised' do
      Gitlab::HTTP::HTTP_ERRORS.each do |error_klass|
        let(:error) { error_klass.new('error') }

        before do
          allow(Gitlab::HTTP).to receive(:post).and_raise(error)
        end

        it 'does not logs the error' do
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception).with(
            an_instance_of(error_klass)
          )
          subject
        end
      end
    end

    context 'when URI::InvalidURIError exception is raised' do
      let(:error) { URI::InvalidURIError.new('invalid uri') }

      before do
        group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
        allow(Gitlab::HTTP).to receive(:post).and_raise(error)
      end

      it 'logs the error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          an_instance_of(URI::InvalidURIError)
        ).once
        subject
      end
    end
  end

  shared_examples 'no HTTP calls are made' do
    context 'when audit event id is passed as param' do
      subject { worker.perform('audit_operation', event.id) }

      it 'makes no HTTP calls' do
        expect(Gitlab::HTTP).not_to receive(:post)

        subject
      end
    end

    context 'when audit event json is passed as param' do
      subject { worker.perform('audit_operation', nil, event.to_json) }

      it 'makes no HTTP calls' do
        expect(Gitlab::HTTP).not_to receive(:post)

        subject
      end
    end
  end

  describe "#perform" do
    context 'when the entity type is a group' do
      it_behaves_like 'a successful audit event stream' do
        let_it_be(:event) { create(:audit_event, :group_event) }
        let_it_be(:audit_operation) { 'audit_operation' }

        let(:group) { event.entity }
      end

      it_behaves_like 'a error is raised' do
        let_it_be(:event) { create(:audit_event, :group_event) }

        let(:group) { event.entity }
      end
    end

    context 'when the entity type is a project that belongs to a group' do
      it_behaves_like 'a successful audit event stream' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:event) { create(:audit_event, :project_event, target_project: project) }
        let_it_be(:audit_operation) { 'audit_operation' }
      end

      it_behaves_like 'a error is raised' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:event) { create(:audit_event, :project_event, target_project: project) }
      end
    end

    context 'when the entity type is a project at a root namespace level' do
      let_it_be(:event) { create(:audit_event, :project_event) }

      it_behaves_like 'no HTTP calls are made'
    end

    context 'when the entity is a NullEntity' do
      let_it_be(:event) { create(:audit_event, :project_event) }

      before do
        event.entity_id = non_existing_record_id
      end

      it_behaves_like 'no HTTP calls are made'
    end

    context 'when the worker is invoked with old parameters', :sidekiq_inline do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:event) { create(:audit_event, :project_event, target_project: project) }
      let_it_be(:audit_operation) { nil }
      let_it_be(:audit_event_id) { nil }

      subject { worker.perform(audit_event_id, event.to_json) }

      include_context 'audit event stream'
    end
  end
end
