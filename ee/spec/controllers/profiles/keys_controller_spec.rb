# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::KeysController, feature_category: :user_profile do
  let(:user) { create(:user) }

  describe '#create' do
    it 'logs the audit event' do
      stub_licensed_features(extended_audit_events: true)

      sign_in(user)

      key = build(:key)

      expect { post :create, params: { key: key.attributes } }.to change { AuditEvent.count }.by(1)
    end
  end
end
