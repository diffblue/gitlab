# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::IssueSidebarBasicEntity do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:issue, reload: true) { create(:issue, project: project, assignees: [user]) }

  let(:serializer) { IssueSerializer.new(current_user: user, project: project) }

  subject(:entity) { serializer.represent(issue, serializer: 'sidebar') }

  it 'contains keys related to issuables' do
    expect(entity).to include(
      :scoped_labels_available, :supports_weight, :supports_iterations,
      :supports_escalation_policies
    )
  end

  it 'contains attributes related to the issue' do
    expect(entity).to include(:supports_epic, :features_available, :request_cve_enabled_for_user)
  end

  it 'contains attributes related to the available features' do
    expect(entity[:features_available]).to include(:health_status, :issue_weights, :epics)
  end

  describe 'request_cve_enabled_for_user' do
    using RSpec::Parameterized::TableSyntax

    where(:is_gitlab_com, :is_public, :is_admin, :expected_value) do
      true  | true  | true  | true
      true  | false | true  | false
      true  | false | false | false
      false | false | true  | false
      false | false | false | false
    end
    with_them do
      before do
        allow(issue.project).to receive(:public?).and_return(is_public)
        issue.project.add_maintainer(user) if is_admin
        allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
      end

      it 'uses the value from request_cve_enabled_for_user' do
        expect(entity[:request_cve_enabled_for_user]).to eq(expected_value)
      end
    end
  end

  describe 'can_update_escalation_policy' do
    before do
      issue.update!(
        work_item_type: WorkItems::Type.default_by_type(:incident)
      )
      stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      project.add_developer(user)
    end

    it 'is present and true' do
      expect(entity[:current_user][:can_update_escalation_policy]).to be(true)
    end

    context 'for a standard issue' do
      subject(:entity) { serializer.represent(create(:issue, project: project), serializer: 'sidebar') }

      it 'is not present' do
        expect(entity[:current_user]).not_to have_key(:can_update_escalation_policy)
      end
    end

    context 'with escalations policies disabled' do
      before do
        stub_licensed_features(escalation_policies: false)
      end

      it 'is not present' do
        expect(entity[:current_user]).not_to have_key(:can_update_escalation_policy)
      end
    end

    context 'without permissions' do
      let(:serializer) { IssueSerializer.new(current_user: create(:user), project: project) }

      it 'is present and false' do
        expect(entity[:current_user]).to have_key(:can_update_escalation_policy)
        expect(entity[:current_user][:can_update_escalation_policy]).to be(false)
      end
    end
  end
end
