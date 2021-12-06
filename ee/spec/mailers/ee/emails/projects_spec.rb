# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Projects do
  include EmailSpec::Matchers

  describe '#user_escalation_rule_deleted_email' do
    let(:rule) { create(:incident_management_escalation_rule, :with_user) }
    let(:user) { rule.user }
    let(:project) { rule.project }
    let(:recipient) { build(:user) }
    let(:elapsed_time) { (rule.elapsed_time_seconds / 60).to_s }

    subject { Notify.user_escalation_rule_deleted_email(user, project, [rule], recipient) }

    it 'has the correct email content', :aggregate_failures do
      is_expected.to have_subject("#{project.name} | User removed from escalation policy")
      is_expected.to have_body_text(user.name)
      is_expected.to have_body_text(user.username)
      is_expected.to have_body_text('was removed from the following escalation policies')
      is_expected.to have_body_text(rule.policy.name)
      is_expected.to have_body_text(elapsed_time)
      is_expected.to have_body_text(rule.status.to_s)
      is_expected.to have_body_text("Please review the updated escalation policies for")
      is_expected.to have_body_text(project.name)
      is_expected.to have_body_text("It is recommended that you reach out to the current on-call responder to ensure continuity of on-call coverage")
    end
  end
end
