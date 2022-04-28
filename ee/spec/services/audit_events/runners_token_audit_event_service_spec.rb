# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::RunnersTokenAuditEventService do
  describe '#security_event' do
    let(:logger) { instance_double(Gitlab::AuditJsonLogger) }

    let(:user) { create(:user) }
    let(:runners_token_prefix) { '' }
    let(:old_token) { "#{runners_token_prefix}old-token" }
    let(:new_token) { "#{runners_token_prefix}new-token" }
    let(:logged_old_token) { "#{runners_token_prefix}old-toke" }
    let(:logged_new_token) { "#{runners_token_prefix}new-toke" }
    let(:service) { described_class.new(user, entity, old_token, new_token) }
    let(:entity_details) do
      {
        entity_id: entity.id,
        entity_type: entity_type
      }
    end

    shared_examples 'logs the event to file' do
      before do
        stub_licensed_features(audit_events: true, extended_audit_events: true)
      end

      it 'logs the event to file', :aggregate_failures do
        freeze_time do
          expected_logger_details = {
            action: :custom,
            author_id: user.id,
            author_name: user.name,
            from: logged_old_token,
            to: logged_new_token,
            custom_message: message,
            created_at: DateTime.current
          }.merge(entity_details)

          expect(service).to receive(:file_logger).and_return(logger)
          expect(logger).to receive(:info).with(expected_logger_details)

          expect { service.security_event }.to change(AuditEvent, :count).by(1)

          security_event = AuditEvent.last

          expect(security_event.details).to include(
            {
              author_name: user.name,
              custom_message: message,
              from: logged_old_token,
              to: logged_new_token
            }
          )

          expect(security_event.author_id).to eq(user.id)
          expect(security_event.entity_type).to eq(entity_details[:entity_type])

          if entity.respond_to?(:full_path)
            expect(security_event.entity_id).to eq(entity.id)
          else
            expect(security_event.entity_id).to eq(user.id)
          end
        end
      end
    end

    context 'for instance' do
      let(:entity) { create(:application_setting) }
      let(:message) { 'Reset instance runner registration token' }
      let(:entity_details) do
        {
          entity_id: user.id,
          entity_type: 'User'
        }
      end

      it_behaves_like 'logs the event to file'
    end

    context 'for group' do
      let(:entity) { create(:group) }
      let(:entity_type) { 'Group' }
      let(:message) { 'Reset group runner registration token' }

      it_behaves_like 'logs the event to file'
    end

    context 'for project' do
      let(:entity) { create(:project) }
      let(:entity_type) { 'Project' }
      let(:message) { 'Reset project runner registration token' }

      it_behaves_like 'logs the event to file'

      context 'with runners_token_prefix set to RUNNERS_TOKEN_PREFIX' do
        let(:runners_token_prefix) { ::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX }

        it_behaves_like 'logs the event to file'
      end
    end
  end
end
