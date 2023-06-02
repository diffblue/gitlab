# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordsController, feature_category: :system_access do
  describe '#create' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      stub_licensed_features(extended_audit_events: true)
    end

    let_it_be(:user) { create(:user) }

    subject { post :create, params: { user: { email: user.email } } }

    it { expect { subject }.to change { AuditEvent.count }.by(1) }
  end
end
