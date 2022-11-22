# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Auditor do
  let(:name) { 'play_with_project_settings' }
  let(:author) { build_stubbed(:user) }
  let(:scope) { build_stubbed(:group) }
  let(:target) { build_stubbed(:project) }
  let(:context) { { name: name, author: author, scope: scope, target: target } }
  let(:add_message) { 'Added an interesting field from project Gotham' }
  let(:remove_message) { 'Removed an interesting field from project Gotham' }
  let(:operation) do
    proc do
      ::Gitlab::Audit::EventQueue.push(add_message)
      ::Gitlab::Audit::EventQueue.push(remove_message)
    end
  end

  let(:logger) { instance_spy(Gitlab::AuditJsonLogger) }

  subject(:auditor) { described_class }

  shared_examples 'only streamed' do
    it 'enqueues an event' do
      expect_any_instance_of(AuditEvent) do |event|
        expect(event).to receive(:stream_to_external_destinations).with(use_json: true, event_name: name)
      end

      audit!
    end

    it 'does not log audit events to file' do
      freeze_time do
        expect(::Gitlab::AuditJsonLogger).not_to receive(:build)

        audit!
      end
    end

    it 'does not log audit events to database' do
      freeze_time do
        expect(AuditEvent).not_to receive(:bulk_insert!)

        audit!
      end
    end
  end

  describe '.audit' do
    context 'when licensed' do
      before do
        stub_licensed_features(admin_audit_log: true, audit_events: true, extended_audit_events: true,
                               external_audit_events: true)
      end

      context 'when recording multiple events', :request_store do
        let(:audit!) { auditor.audit(context, &operation) }

        context 'when the event is created within a transaction' do
          let_it_be(:scope) { create(:group) }
          let_it_be(:target) { create(:project) }

          before do
            scope.external_audit_event_destinations.create!(destination_url: 'http://example.com')
          end

          it 'does not raise Sidekiq::Worker::EnqueueFromTransactionError' do
            ApplicationRecord.transaction do
              expect { audit! }.not_to raise_error
            end
          end
        end

        it 'interacts with the event queue in correct order', :aggregate_failures do
          allow(Gitlab::Audit::EventQueue).to receive(:begin!).and_call_original
          allow(Gitlab::Audit::EventQueue).to receive(:end!).and_call_original

          audit!

          expect(Gitlab::Audit::EventQueue).to have_received(:begin!).ordered
          expect(Gitlab::Audit::EventQueue).to have_received(:end!).ordered
        end

        it 'bulk-inserts audit events to database' do
          expect(AuditEvent).to receive(:bulk_insert!).with(include(kind_of(AuditEvent)), returns: :ids)

          audit!
        end

        it 'records audit events in correct order', :aggregate_failures do
          expect { audit! }.to change(AuditEvent, :count).by(2)

          event_messages = AuditEvent.order(:id).map { |event| event.details[:custom_message] }

          expect(event_messages).to eq([add_message, remove_message])
        end

        it 'logs audit events to database', :aggregate_failures do
          freeze_time do
            audit!

            audit_event = AuditEvent.last

            expect(audit_event.author_id).to eq(author.id)
            expect(audit_event.entity_id).to eq(scope.id)
            expect(audit_event.entity_type).to eq(scope.class.name)
            expect(audit_event.created_at).to eq(Time.zone.now)
            expect(audit_event.details[:target_id]).to eq(target.id)
            expect(audit_event.details[:target_type]).to eq(target.class.name)
          end
        end

        it 'logs audit events to file' do
          expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

          audit!

          expect(logger).to have_received(:info).exactly(2).times.with(
            hash_including(
              'id' => kind_of(Integer),
              'author_id' => author.id,
              'author_name' => author.name,
              'entity_id' => scope.id,
              'entity_type' => scope.class.name,
              'details' => kind_of(Hash)
            )
          )
        end

        it 'enqueues an event stream' do
          expect_any_instance_of(AuditEvent) do |event|
            expect(event).to receive(:stream_to_external_destinations).with(use_json: true, event_name: name)
          end

          audit!
        end

        context 'when overriding the create datetime' do
          let(:context) { { name: name, author: author, scope: scope, target: target, created_at: 3.weeks.ago } }

          it 'logs audit events to database', :aggregate_failures do
            freeze_time do
              audit!

              audit_event = AuditEvent.last

              expect(audit_event.author_id).to eq(author.id)
              expect(audit_event.entity_id).to eq(scope.id)
              expect(audit_event.entity_type).to eq(scope.class.name)
              expect(audit_event.created_at).to eq(3.weeks.ago)
              expect(audit_event.details[:target_id]).to eq(target.id)
              expect(audit_event.details[:target_type]).to eq(target.class.name)
            end
          end

          it 'logs audit events to file' do
            freeze_time do
              expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

              audit!

              expect(logger).to have_received(:info).exactly(2).times.with(
                hash_including(
                  'author_id' => author.id,
                  'author_name' => author.name,
                  'entity_id' => scope.id,
                  'entity_type' => scope.class.name,
                  'details' => kind_of(Hash),
                  'created_at' => 3.weeks.ago.iso8601(3)
                )
              )
            end
          end
        end

        context 'when overriding the additional_details' do
          additional_details = { action: :custom, from: false, to: true }
          let(:context) do
            { name: name,
              author: author,
              scope: scope,
              target: target,
              created_at: Time.zone.now,
              additional_details: additional_details }
          end

          it 'logs audit events to database' do
            freeze_time do
              audit!

              expect(AuditEvent.last.details).to include(additional_details)
            end
          end

          it 'logs audit events to file' do
            freeze_time do
              expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

              audit!

              expect(logger).to have_received(:info).exactly(2).times.with(
                hash_including(
                  'details' => hash_including('action' => 'custom', 'from' => 'false', 'to' => 'true'),
                  'action' => 'custom',
                  'from' => 'false',
                  'to' => 'true'
                )
              )
            end
          end
        end

        context 'when overriding the target_details' do
          target_details = "this is my target details"
          let(:context) do
            { name: name,
              author: author,
              scope: scope,
              target: target,
              created_at: Time.zone.now,
              target_details: target_details }
          end

          it 'logs audit events to database' do
            freeze_time do
              audit!

              audit_event = AuditEvent.last
              expect(audit_event.details).to include({ target_details: target_details })
              expect(audit_event.target_details).to eq(target_details)
            end
          end

          it 'logs audit events to file' do
            freeze_time do
              expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

              audit!

              expect(logger).to have_received(:info).exactly(2).times.with(
                hash_including(
                  'details' => hash_including('target_details' => target_details),
                  'target_details' => target_details
                )
              )
            end
          end
        end

        context 'when overriding the ip address' do
          ip_address = '192.168.8.8'
          let(:context) { { name: name, author: author, scope: scope, target: target, ip_address: ip_address } }

          context 'when :admin_audit_log feature is available it logs ip address' do
            before do
              stub_licensed_features(admin_audit_log: true)
            end
            it 'logs audit events to database' do
              audit!

              expect(AuditEvent.last.ip_address).to eq(ip_address)
            end

            it 'logs audit events to file' do
              expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

              audit!

              expect(logger).to have_received(:info).exactly(2).times.with(
                hash_including('ip_address' => ip_address)
              )
            end

            context 'when :admin_audit_log feature is not available it does not log ip address' do
              before do
                stub_licensed_features(admin_audit_log: false)
              end
              it 'does not log audit event to database' do
                freeze_time do
                  audit!

                  expect(AuditEvent.last.ip_address).to be(nil)
                end
              end

              it 'does not log audit events to file' do
                freeze_time do
                  expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

                  audit!

                  expect(logger).to have_received(:info).exactly(2).times.with(
                    hash_excluding(
                      'ip_address' => ip_address
                    )
                  )
                end
              end
            end
          end
        end

        context 'when event is only streamed' do
          let(:context) do
            { name: name, author: author, scope: scope, target: target, created_at: 3.weeks.ago, stream_only: true }
          end

          it_behaves_like 'only streamed'
        end
      end

      context 'when recording single event' do
        let(:audit!) { auditor.audit(context) }
        let(:context) do
          {
            name: name, author: author, scope: scope, target: target,
            message: 'Project has been deleted'
          }
        end

        it 'logs audit event to database', :aggregate_failures do
          expect { audit! }.to change(AuditEvent, :count).by(1)

          audit_event = AuditEvent.last

          expect(audit_event.author_id).to eq(author.id)
          expect(audit_event.entity_id).to eq(scope.id)
          expect(audit_event.entity_type).to eq(scope.class.name)
          expect(audit_event.details[:target_id]).to eq(target.id)
          expect(audit_event.details[:target_type]).to eq(target.class.name)
          expect(audit_event.details[:custom_message]).to eq('Project has been deleted')
        end

        it 'does not bulk insert and uses save to insert' do
          expect(AuditEvent).not_to receive(:bulk_insert!)
          expect_next_instance_of(AuditEvent) do |instance|
            expect(instance).to receive(:save!)
          end

          audit!
        end

        it 'logs audit events to file' do
          expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

          audit!

          expect(logger).to have_received(:info).once.with(
            hash_including(
              'id' => AuditEvent.last.id,
              'author_id' => author.id,
              'author_name' => author.name,
              'entity_id' => scope.id,
              'entity_type' => scope.class.name,
              'details' => kind_of(Hash),
              'custom_message' => 'Project has been deleted'
            )
          )
        end

        context 'when event is only streamed' do
          let(:context) do
            {
              name: name,
              author: author,
              scope: scope,
              target: target,
              created_at: 3.weeks.ago,
              stream_only: true,
              message: 'test'
            }
          end

          it_behaves_like 'only streamed'
        end
      end

      context 'when audit events are invalid' do
        before do
          allow(AuditEvent).to receive(:bulk_insert!).and_raise(ActiveRecord::RecordInvalid)
          allow(Gitlab::ErrorTracking).to receive(:track_exception)
        end

        it 'tracks error' do
          auditor.audit(context, &operation)

          expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
            kind_of(ActiveRecord::RecordInvalid),
            { audit_operation: name }
          )
        end

        it 'does not throw exception' do
          expect { auditor.audit(context, &operation) }.not_to raise_exception
        end
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(admin_audit_log: false, audit_events: false, extended_audit_events: false)
      end

      let(:audit!) { auditor.audit(context, &operation) }

      it 'does not logs audit event to database' do
        expect { audit! }.not_to change { AuditEvent.count }
      end

      it 'does not logs audit events to file' do
        expect(::Gitlab::AuditJsonLogger).not_to receive(:build)

        audit!
      end
    end
  end

  describe '#audit_enabled?' do
    using RSpec::Parameterized::TableSyntax

    where(:admin_audit_log, :audit_events, :extended_audit_events, :result) do
      true  | false | false | true
      false | true  | false | true
      false | false | true  | true
      false | false | false | false
    end

    with_them do
      before do
        stub_licensed_features(
          admin_audit_log: admin_audit_log,
          audit_events: audit_events,
          extended_audit_events: extended_audit_events
        )
      end

      it 'returns the correct result when feature is available' do
        expect(auditor.new(context).audit_enabled?).to be(result)
      end
    end
  end
end
