# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/issuable/_sidebar.html.haml' do
  let_it_be(:user) { create(:user) }

  subject(:rendered) do
    render 'shared/issuable/sidebar', issuable_sidebar: IssueSerializer.new(current_user: user)
      .represent(issuable, serializer: 'sidebar'), assignees: []
  end

  context 'project in a group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:incident) { create(:incident, project: project) }

    before do
      assign(:project, project)
    end

    context 'issuable that supports iterations' do
      let(:issuable) { issue }

      it 'shows iteration dropdown' do
        expect(rendered).to have_css('[data-testid="iteration_container"]')
      end
    end

    context 'issuable does not support iterations' do
      let(:issuable) { incident }

      it 'does not show iteration dropdown' do
        expect(rendered).not_to have_css('[data-testid="iteration_container"]')
      end
    end

    context 'issuable that does not support escalation policies' do
      let(:issuable) { incident }

      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      end

      it 'shows escalation policy dropdown' do
        expect(rendered).to have_css('[data-testid="escalation_policy_container"]')
      end
    end

    context 'issuable that supports escalation policies' do
      let(:issuable) { issue }

      it 'does not show escalation policy dropdown' do
        expect(rendered).not_to have_css('[data-testid="escalation_policy_container"]')
      end
    end
  end

  context 'non-group project' do
    let_it_be(:project) { create(:project) }

    let(:issuable) { create(:issue, project: project) }

    before do
      assign(:project, project)
    end

    it 'does not show iteration dropdown' do
      expect(rendered).not_to have_css('[data-testid="iteration_container"]')
    end
  end
end
