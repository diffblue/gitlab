# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationsController, feature_category: :shared do
  let(:admin) { create(:admin) }
  let(:application) { create(:oauth_application, owner_id: nil, owner_type: nil) }

  before do
    sign_in(admin)
  end

  describe 'POST #create' do
    it 'creates the application' do
      stub_licensed_features(extended_audit_events: true)

      create_params = attributes_for(:application, trusted: true)

      expect do
        post :create, params: { doorkeeper_application: create_params }
      end.to change { AuditEvent.count }.by(1)
    end
  end
end
