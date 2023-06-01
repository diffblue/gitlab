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

    it "generates audit events" do
      expect { subject }.to change { AuditEvent.count }.by(1)

      audit_event = AuditEvent.last
      expect(audit_event.attributes).to include({
        "entity_id" => user.id,
        "entity_type" => "User",
        "entity_path" => nil,
        "author_name" => "An unauthenticated user",
        "target_type" => "User",
        "target_details" => user.email,
        "target_id" => user.id
      })
      expect(audit_event.details).to include({
        custom_message: "Ask for password reset",
        author_name: "An unauthenticated user",
        target_type: "User",
        target_details: user.email
      })
    end
  end
end
