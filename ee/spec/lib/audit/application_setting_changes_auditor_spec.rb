# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ApplicationSettingChangesAuditor, feature_category: :audit_events do
  include StubENV

  describe '.audit_changes' do
    let!(:user) { create(:user) }
    let!(:application_setting) { ApplicationSetting.create_from_defaults }
    let!(:application_setting_auditor_instance) { described_class.new(user, application_setting) }

    before do
      stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
    end

    shared_examples 'application_setting_audit_events_from_to' do
      it 'calls auditor' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(
          {
            name: "application_setting_updated",
            author: user,
            scope: be_an_instance_of(Gitlab::Audit::InstanceScope),
            target: application_setting,
            message: "Changed #{change_field} from #{change_from} to #{change_to}",
            additional_details: {
              change: change_field.to_s,
              from: change_from,
              target_details: change_field.humanize,
              to: change_to
            },
            target_details: change_field.humanize
          }
        ).and_call_original

        expect { application_setting_auditor_instance.execute }.to change { AuditEvent.count }.by(1)

        event = AuditEvent.last
        expect(event.details[:from]).to eq change_from
        expect(event.details[:to]).to eq change_to
        expect(event.details[:change]).to eq change_field
      end
    end

    context 'when any model change is made' do
      let(:change_from) { 0 }
      let(:change_to) { 10 }
      let(:change_field) { "default_project_visibility" }

      before do
        application_setting.update!(default_project_visibility: 10)
      end

      it_behaves_like 'application_setting_audit_events_from_to'
    end

    context 'when ignored column is updated' do
      it 'does not create an event for _html columns' do
        application_setting.update!(after_sign_up_text_html: "test_text")

        expect(AuditEvents::AuditEventStreamingWorker).not_to receive(:perform_async)
        expect { application_setting_auditor_instance.execute }.not_to change { AuditEvent.count }
      end
    end

    context 'when encrypted column is updated' do
      it 'creates an event for encrypted columns' do
        application_setting.update!(anthropic_api_key: 'ANTHROPIC_API_KEY')

        expect { application_setting_auditor_instance.execute }.to change { AuditEvent.count }.by(1)

        event = AuditEvent.last
        expect(event.details[:change]).to eq "anthropic_api_key"
        expect(event.details[:to]).to eq nil # For encrypted column encrypted_ column contains the cipher
      end
    end
  end
end
