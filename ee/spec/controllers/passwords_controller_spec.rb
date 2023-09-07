# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordsController, feature_category: :system_access do
  describe '#create' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      stub_licensed_features(extended_audit_events: true)
    end

    let_it_be(:user) { create(:user) }

    subject(:post_create) { post :create, params: { user: { email: email } } }

    describe "#update" do
      context "when there is error updating the password" do
        subject do
          put :update, params: {
            user: {
              password: password,
              password_confirmation: password_confirmation,
              reset_password_token: reset_password_token
            }
          }
        end

        let(:password) { "short" } # short invalid password
        let(:password_confirmation) { password }
        let(:reset_password_token) { user.send_reset_password_instructions }
        let(:user) { create(:user, password_automatically_set: true, password_expires_at: 10.minutes.ago) }

        it "calls `::Audit::UserPasswordResetAuditor` with correct args" do
          expect(::Audit::UserPasswordResetAuditor).to receive(:new).with(user, user,
            instance_of(String)).and_call_original

          subject
        end
      end
    end

    context "when email exists" do
      let(:email) { user.email }

      it "generates an audit event" do
        expect { post_create }.to change { AuditEvent.count }.by(1)

        expect(AuditEvent.last).to have_attributes({
          attributes: hash_including({
            "entity_id" => user.id,
            "entity_type" => "User",
            "entity_path" => nil,
            "author_name" => "An unauthenticated user",
            "target_type" => "User",
            "target_details" => user.email,
            "target_id" => user.id
          }),
          details: hash_including({
            custom_message: "Ask for password reset",
            author_name: "An unauthenticated user",
            target_type: "User",
            target_details: user.email
          })
        })
      end
    end

    context "when email does not exist" do
      let(:email) { "#{user.email}.nonexistent" }

      it "generates an audit event" do
        nonuser = ::Gitlab::Audit::UnauthenticatedAuthor.new

        expect { post_create }.to change { AuditEvent.count }.by(1)

        expect(AuditEvent.last).to have_attributes({
          attributes: hash_including({
            "entity_id" => nonuser.id,
            "entity_type" => "User",
            "entity_path" => nil,
            "author_name" => "An unauthenticated user",
            "target_type" => "User",
            "target_details" => email,
            "target_id" => nonuser.id
          }),
          details: hash_including({
            custom_message: "Ask for password reset",
            author_name: "An unauthenticated user",
            target_type: "User",
            target_details: email
          })
        })
      end
    end
  end
end
