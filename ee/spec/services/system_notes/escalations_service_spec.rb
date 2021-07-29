# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::EscalationsService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:author) { User.alert_bot }

  describe '#notify_via_escalation' do
    subject { described_class.new(noteable: noteable, project: project).notify_via_escalation([user, user_2], escalation_policy: escalation_policy) }

    let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }
    let_it_be(:noteable) { create(:alert_management_alert, project: project) }

    it_behaves_like 'a system note' do
      let(:action) { 'new_alert_added' }
    end

    it 'posts the correct text to the system note' do
      expect(subject.note).to match("notified #{user.to_reference} and #{user_2.to_reference} of this alert via escalation policy **#{escalation_policy.name}**")
    end
  end
end
