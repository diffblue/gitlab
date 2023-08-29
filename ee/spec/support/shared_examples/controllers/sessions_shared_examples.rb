# frozen_string_literal: true

RSpec.shared_examples 'an auditable failed authentication' do
  it 'log an audit event', :aggregate_failures do
    audit_context = {
      name: "login_failed_with_#{method.downcase}_authentication",
      message: "Failed to login with #{method} authentication",
      target: user,
      scope: user,
      author: user,
      additional_details: {
        failed_login: method
      }
    }

    expect(Audit::UnauthenticatedSecurityEventAuditor).to receive(:new).with(user, method).and_call_original
    expect(Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).and_call_original

    operation
  end
end
