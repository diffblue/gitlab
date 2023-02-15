# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPolicyHelper, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#escalation_policy_data' do
    subject(:data) { helper.escalation_policy_data(project) }

    before do
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).with(
        user,
        :admin_incident_management_escalation_policy, project
      ).and_return(false)
    end

    it 'returns escalation policies data' do
      is_expected.to eq(
        'project-path' => project.full_path,
        'empty_escalation_policies_svg_path' => helper.image_path('illustrations/empty-state/empty-escalation.svg'),
        'user_can_create_escalation_policy' => 'false',
        'access_level_description_path' => Gitlab::Routing.url_helpers.project_project_members_url(
          project,
          sort: 'access_level_desc'
        )
      )
    end
  end
end
