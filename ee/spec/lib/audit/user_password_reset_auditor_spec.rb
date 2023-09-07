# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::UserPasswordResetAuditor, feature_category: :audit_events do
  let_it_be(:user) { create(:user) }
  let_it_be(:remote_ip) { "127.0.0.1" }

  describe "#audit_reset_failure" do
    subject(:audit_reset_failure) { described_class.new(user, user, remote_ip).audit_reset_failure }

    context "when there are no errors in password" do
      before do
        allow(user).to receive(:errors).and_return({})
      end

      it "doesn't audit" do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        audit_reset_failure
      end
    end

    shared_examples "logs audit event with correct reason" do |reason|
      it "does audit with correct reason" do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          { name: "password_reset_failed",
            author: user,
            scope: user,
            target: user,
            target_details: user.email,
            message: reason,
            ip_address: remote_ip }
        ).and_call_original

        audit_reset_failure
      end
    end

    context "when there is a single error in password" do
      before do
        allow(user).to receive(:errors).and_return({ password: ["must contain a letter"] })
      end

      it_behaves_like "logs audit event with correct reason",
        "Password reset failed with reason: must contain a letter"
    end

    context "when there are multiple errors in password" do
      before do
        allow(user).to receive(:errors).and_return({
          password: ["must contain a letter",
            "must not contain commonly used characters"]
        })
      end

      it_behaves_like "logs audit event with correct reason",
        "Password reset failed with reasons: must contain a letter and must not contain commonly used characters"
    end
  end
end
