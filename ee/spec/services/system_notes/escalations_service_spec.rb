# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::EscalationsService, feature_category: :incident_management do
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:author) { User.alert_bot }
  let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }

  describe '#notify_via_escalation' do
    subject { described_class.new(noteable: noteable, project: project).notify_via_escalation([user, user_2], escalation_policy: escalation_policy, type: type) }

    let_it_be(:noteable) { create(:alert_management_alert, project: project) }
    let_it_be(:type) { :alert }

    it_behaves_like 'a system note' do
      let(:action) { 'new_alert_added' }
    end

    it 'posts the correct text to the system note' do
      expect(subject.note).to match("notified #{user.to_reference} and #{user_2.to_reference} of this #{type} via escalation policy **#{escalation_policy.name}**")
    end
  end

  describe '#start_escalation' do
    let_it_be(:noteable) { create(:issue, project: project) }
    let_it_be(:author) { user }

    subject do
      described_class
      .new(noteable: noteable, project: project)
      .start_escalation(escalation_policy, user)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'paging_started' }
    end

    it 'posts the correct text to the system note' do
      expect(subject.note).to match("paged escalation policy [#{escalation_policy.name}](#{project_incident_management_escalation_policies_path(project)})")
    end
  end
end
