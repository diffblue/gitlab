# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::CreateService, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  let(:opts) { { email: 'new@email.com', user: user } }

  subject(:service) { described_class.new(user, opts) }

  describe '#execute' do
    it 'registers a security event' do
      stub_licensed_features(extended_audit_events: true)

      expect { service.execute }.to change { AuditEvent.count }.by(1)
    end
  end
end
