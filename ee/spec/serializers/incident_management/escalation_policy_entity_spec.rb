# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPolicyEntity do
  let(:policy) { create(:incident_management_escalation_policy) }
  let(:url) { Gitlab::Routing.url_helpers.project_incident_management_escalation_policies_url(policy.project) }
  let(:project_url) { Gitlab::Routing.url_helpers.project_url(policy.project) }

  subject { described_class.new(policy) }

  describe '.as_json' do
    it 'includes escalation policy attributes' do
      attributes = subject.as_json

      expect(attributes[:name]).to eq(policy.name)
      expect(attributes[:url]).to eq(url)
      expect(attributes[:project_name]).to eq(policy.project.name)
      expect(attributes[:project_url]).to eq(project_url)
    end
  end
end
