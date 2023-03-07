# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::DestroyService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user) }

  it 'does not destroy LDAP key' do
    key = create(:ldap_key)

    expect { subject.execute(key) }.not_to change(Key, :count)
    expect(key).not_to be_destroyed
  end

  context 'audit events' do
    context 'when licensed' do
      before do
        stub_licensed_features(admin_audit_log: true, audit_events: true, extended_audit_events: true)
      end

      it 'creates an audit event', :aggregate_failures do
        key = create(:personal_key)

        expect { subject.execute(key) }.to change(AuditEvent, :count).by(1)

        expect(AuditEvent.last).to have_attributes(
          author: user,
          entity_id: key.user.id,
          target_id: key.id,
          target_type: key.class.name,
          target_details: key.title,
          details: include(custom_message: 'Removed SSH key')
        )
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(admin_audit_log: false, audit_events: false, extended_audit_events: false)
        end

        it 'does not track audit event' do
          key = create(:personal_key)

          expect { subject.execute(key) }.not_to change { AuditEvent.count }
        end
      end
    end
  end

  it 'returns the correct value' do
    key = build(:personal_key)
    allow(key).to receive(:destroy).and_return(true)

    expect(subject.execute(key)).to eq(true)
  end

  context 'when destroy operation fails' do
    let(:key) { build(:personal_key) }

    before do
      allow(key).to receive(:destroy).and_return(false)
    end

    it 'does not create an audit event' do
      expect { subject.execute(key) }.not_to change(AuditEvent, :count)
    end

    it 'returns the correct value' do
      expect(subject.execute(key)).to eq(false)
    end
  end
end
