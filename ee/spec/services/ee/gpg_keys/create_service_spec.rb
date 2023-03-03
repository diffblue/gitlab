# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeys::CreateService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  let(:params) { attributes_for(:gpg_key) }

  subject { described_class.new(user, params) }

  describe '.audit' do
    context 'when licensed' do
      before do
        stub_licensed_features(admin_audit_log: true, audit_events: true, extended_audit_events: true)
      end

      it 'creates an audit event', :aggregate_failures do
        expect { subject.execute }.to change(GpgKey, :count).by(1)
                                                            .and change(AuditEvent, :count).by(1)

        key = user.gpg_keys.last

        expect(AuditEvent.last).to have_attributes(
          author: user,
          entity_id: key.user.id,
          target_id: key.id,
          target_type: key.class.name,
          target_details: key.user.name,
          details: include(custom_message: 'Added GPG key')
        )
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(admin_audit_log: false, audit_events: false, extended_audit_events: false)
      end

      it 'creates an audit event' do
        expect { subject.execute }.to change(GpgKey, :count).by(1)
                                                            .and not_change(AuditEvent, :count)
      end
    end
  end

  it 'returns the correct value' do
    expect(subject.execute).to eq(GpgKey.last)
  end

  context 'when create operation fails' do
    let(:params) { attributes_for(:gpg_key).except(:key) }

    it 'does not create an audit event' do
      expect { subject.execute }.not_to change(AuditEvent, :count)
    end

    it 'returns the correct value' do
      expect(subject.execute).to be_a_new(GpgKey)
    end
  end
end
