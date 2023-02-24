# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::ApplicationsController, feature_category: :system_access do
  let(:user) { create(:user) }

  context 'project members' do
    before do
      sign_in(user)
    end

    describe 'POST #create' do
      it 'logs the audit event' do
        stub_licensed_features(extended_audit_events: true)

        sign_in(user)

        application = build(:oauth_application)
        application_attributes = application.attributes.merge("scopes" => [])

        expect { post :create, params: { doorkeeper_application: application_attributes } }.to change { AuditEvent.count }.by(1)
      end
    end
  end
end
