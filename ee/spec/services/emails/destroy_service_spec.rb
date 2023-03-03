# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::DestroyService, feature_category: :user_profile do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  subject(:service) { described_class.new(user, user: user) }

  describe '#execute' do
    it 'registers a security event' do
      stub_licensed_features(extended_audit_events: true)

      expect { service.execute(email) }.to change { AuditEvent.count }.by(1)
    end
  end
end
