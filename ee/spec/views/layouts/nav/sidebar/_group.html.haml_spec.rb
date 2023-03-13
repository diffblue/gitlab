# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_group' do
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    assign(:group, group)
  end

  describe 'Epics menu' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) do
      create(:group).tap do |g|
        g.add_maintainer(user)
      end
    end

    before do
      stub_licensed_features(epics: true)

      allow(view).to receive(:current_user).and_return(user)
    end

    it 'has a link to the epic list path' do
      render

      expect(rendered).to have_link('Epics', href: group_epics_path(group))
    end

    describe 'List' do
      it 'has a link to the epic list path' do
        render

        expect(rendered).to have_link('List', href: group_epics_path(group))
      end
    end

    describe 'Boards' do
      it 'has a link to the epic boards path' do
        render

        expect(rendered).to have_link('Boards', href: group_epic_boards_path(group))
      end
    end

    describe 'Roadmap' do
      it 'has a link to the epic roadmap path' do
        render

        expect(rendered).to have_link('Roadmap', href: group_roadmap_path(group))
      end
    end
  end

  describe 'Issues menu' do
    describe 'iterations link' do
      let_it_be(:current_user) { create(:user) }

      before do
        group.add_guest(current_user)

        allow(view).to receive(:current_user).and_return(current_user)
      end

      context 'with iterations licensed feature available' do
        before do
          stub_licensed_features(iterations: true)
        end

        it 'is visible' do
          render

          expect(rendered).to have_text 'Iterations'
        end
      end

      context 'with iterations licensed feature disabled' do
        before do
          stub_licensed_features(iterations: false)
        end

        it 'is not visible' do
          render

          expect(rendered).not_to have_text 'Iterations'
        end
      end
    end
  end

  describe 'Security and compliance menu', :saas do
    let(:group) { create(:group_with_plan, plan: :ultimate_plan) }

    before do
      enable_namespace_license_check!
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'is visible' do
        render

        expect(rendered).to have_link 'Security and Compliance'
        expect(rendered).to have_link 'Security'
      end
    end

    context 'when compliance dashboard feature is enabled' do
      before do
        stub_licensed_features(group_level_compliance_dashboard: true)
      end

      context 'when the user does not have access to Compliance dashboard' do
        it 'is not visible' do
          render

          expect(rendered).not_to have_link 'Security and Compliance'
          expect(rendered).not_to have_link 'Compliance'
        end
      end

      context 'when the user has access to Compliance dashboard' do
        before do
          group.add_owner(user)
          allow(view).to receive(:current_user).and_return(user)
        end

        it 'is visible' do
          render

          expect(rendered).to have_link 'Security and Compliance'
          expect(rendered).to have_link 'Compliance'
        end
      end
    end

    context 'when credentials inventory feature is enabled' do
      shared_examples_for 'Credentials tab is not visible' do
        it 'does not show the `Credentials` tab' do
          render

          expect(rendered).not_to have_link 'Security and Compliance'
          expect(rendered).not_to have_link 'Credentials'
        end
      end

      before do
        stub_licensed_features(credentials_inventory: true)
      end

      context 'when the group does not enforce managed accounts' do
        it_behaves_like 'Credentials tab is not visible'
      end

      context 'when the group enforces managed accounts' do
        before do
          allow(group).to receive(:enforced_group_managed_accounts?).and_return(true)
        end

        context 'when the user has privileges to view Credentials' do
          before do
            group.add_owner(user)
            allow(view).to receive(:current_user).and_return(user)
          end

          it 'is visible' do
            render

            expect(rendered).to have_link 'Security and Compliance'
            expect(rendered).to have_link 'Credentials'
          end
        end

        context 'when the user does not have privileges to view Credentials' do
          it_behaves_like 'Credentials tab is not visible'
        end
      end
    end

    context 'when audit events feature is enabled' do
      before do
        stub_licensed_features(audit_events: true)
      end

      context 'when the user does not have access to Audit Events' do
        before do
          group.add_guest(user)
          allow(view).to receive(:current_user).and_return(user)
        end

        it 'is not visible' do
          render

          expect(rendered).not_to have_link 'Security and Compliance'
          expect(rendered).not_to have_link 'Audit events'
        end
      end

      context 'when the user has access to Audit Events' do
        before do
          group.add_owner(user)
          allow(view).to receive(:current_user).and_return(user)
        end

        it 'is visible' do
          render

          expect(rendered).to have_link 'Security and Compliance'
          expect(rendered).to have_link 'Audit events'
        end
      end
    end

    context 'when security dashboard feature is disabled', :saas do
      let(:group) { create(:group_with_plan, plan: :bronze_plan) }

      it 'is not visible' do
        render

        expect(rendered).not_to have_link 'Security and Compliance'
      end
    end
  end

  describe 'Analytics menu' do
    let_it_be(:owner) { create(:user) }
    let_it_be(:guest) { create(:user) }

    let_it_be_with_refind(:group) do
      create(:group).tap do |g|
        g.add_maintainer(owner)
        g.add_guest(guest)
      end
    end

    before do
      allow(view).to receive(:current_user).and_return(owner)
    end

    describe 'CI/CD analytics' do
      let(:ci_cd_analytics_enabled) { true }

      before do
        stub_licensed_features(group_ci_cd_analytics: ci_cd_analytics_enabled)
      end

      it 'has a link to the CI/CD analytics page' do
        render

        expect(rendered).to have_link('CI/CD', href: group_analytics_ci_cd_analytics_path(group))
      end

      describe 'feature is disabled' do
        let(:ci_cd_analytics_enabled) { false }

        specify do
          render

          expect(rendered).not_to have_link('CI/CD')
        end
      end
    end

    describe 'DevOps' do
      context 'DevOps adoption feature is available' do
        before do
          stub_licensed_features(group_level_devops_adoption: true)
        end

        it 'is visible' do
          render

          expect(rendered).to have_text 'DevOps adoption'
        end
      end

      context 'DevOps adoption feature is not available' do
        before do
          stub_licensed_features(group_level_devops_adoption: false)
        end

        it 'is not visible' do
          render

          expect(rendered).not_to have_text 'DevOps adoption'
        end
      end
    end

    describe 'Repository analytics' do
      before do
        stub_licensed_features(group_coverage_reports: true, group_repository_analytics: true)
      end

      it 'has a link to the Repository analytics page' do
        render

        expect(rendered).to have_link('Repository', href: group_analytics_repository_analytics_path(group))
      end

      describe 'feature is not available' do
        specify do
          stub_licensed_features(group_coverage_reports: false)

          render

          expect(rendered).not_to have_link('Repository', href: group_analytics_repository_analytics_path(group))
        end
      end
    end

    describe 'contribution analytics tab' do
      before do
        allow(view).to receive(:current_user).and_return(guest)
      end

      context 'contribution analytics feature is available' do
        before do
          stub_licensed_features(contribution_analytics: true)
        end

        it 'is visible' do
          render

          expect(rendered).to have_text 'Contribution'
        end
      end

      context 'contribution analytics feature is not available' do
        before do
          stub_licensed_features(contribution_analytics: false)
        end

        context 'we do not show Contribution' do
          it 'is not visible' do
            render

            expect(rendered).not_to have_text 'Contribution'
          end
        end
      end

      context 'no license installed' do
        before do
          allow(License).to receive(:current).and_return(nil)
          stub_application_setting(check_namespace_plan: false)

          allow(view).to receive(:can?) { |*args| Ability.allowed?(*args) }
        end

        it 'is not visible' do
          render

          expect(rendered).not_to have_text 'Contribution'
        end
      end

      it 'is visible' do
        stub_licensed_features(contribution_analytics: true)

        render

        expect(rendered).to have_text 'Contribution'
      end

      describe 'group issue boards link' do
        context 'when multiple issue board is disabled' do
          it 'shows link text in singular' do
            render

            expect(rendered).to have_text 'Board'
          end
        end

        context 'when multiple issue board is enabled' do
          before do
            stub_licensed_features(multiple_group_issue_boards: true)
          end

          it 'shows link text in plural' do
            render

            expect(rendered).to have_text 'Boards'
          end
        end
      end
    end

    describe 'Insights analytics' do
      it 'has a link to the insights analytics page' do
        allow(group).to receive(:insights_available?).and_return(true)

        render

        expect(rendered).to have_link('Insights', href: group_insights_path(group))
      end

      describe 'feature is disabled' do
        specify do
          render

          expect(rendered).not_to have_link('Insights')
        end
      end
    end

    describe 'Issue analytics' do
      let(:issues_analytics_enabled) { true }

      before do
        stub_licensed_features(issues_analytics: issues_analytics_enabled)
      end

      it 'has a link to the Issue analytics page' do
        render

        expect(rendered).to have_link('Issue', href: group_issues_analytics_path(group))
      end

      describe 'feature is disabled' do
        let(:issues_analytics_enabled) { false }

        specify do
          render

          expect(rendered).not_to have_link(exact_text: 'Issue')
        end
      end
    end

    describe 'Productivity analytics' do
      let(:productivity_analytics_enabled) { true }

      before do
        stub_licensed_features(productivity_analytics: productivity_analytics_enabled)
      end

      it 'has a link to the Productivity analytics page' do
        render

        expect(rendered).to have_link('Productivity', href: group_analytics_productivity_analytics_path(group))
      end

      describe 'feature is disabled' do
        let(:productivity_analytics_enabled) { false }

        specify do
          render

          expect(rendered).not_to have_link('Productivity', href: group_analytics_productivity_analytics_path(group))
        end
      end
    end

    describe 'Cycle analytics' do
      let(:cycle_analytics_enabled) { true }

      before do
        stub_licensed_features(cycle_analytics_for_groups: cycle_analytics_enabled)
      end

      it 'has a link to the Cycle analytics page' do
        render

        expect(rendered).to have_link('Value stream', href: group_analytics_cycle_analytics_path(group))
      end

      describe 'feature is disabled' do
        let(:cycle_analytics_enabled) { false }

        specify do
          render

          expect(rendered).not_to have_link('Value stream')
        end
      end
    end
  end

  describe 'Wiki Menu' do
    let(:wiki_enabled) { true }

    before do
      stub_licensed_features(group_wikis: wiki_enabled)

      allow(view).to receive(:current_user).and_return(user)
    end

    describe 'when wiki is available to user' do
      it 'shows the wiki tab with the wiki internal link' do
        render

        expect(rendered).to have_link('Wiki', href: group.wiki.web_url)
      end
    end

    describe 'when wiki is unavailable to user' do
      let(:wiki_enabled) { false }

      it 'does not show the wiki tab' do
        render

        expect(rendered).not_to have_link('Wiki', href: group.wiki.web_url)
      end
    end
  end

  describe 'Settings' do
    let(:administration_nav_enabled) { true }

    before do
      group.add_owner(user)

      stub_licensed_features(
        usage_quotas: true,
        group_saml: true,
        group_webhooks: true,
        saml_group_sync: true,
        ldap_group_sync: true
      )
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'has a link to the LDAP sync settings page' do
      allow(::Gitlab.config.ldap).to receive_messages(enabled: true)

      expect_rendered.to have_link('LDAP Synchronization', href: group_ldap_group_links_path(group))
    end

    it 'has a link to the SAML SSO settings page' do
      expect_rendered.to have_link('SAML SSO', href: group_saml_providers_path(group))
    end

    it 'has a link to the SAML group links settings page' do
      create(:saml_provider, group: group, enabled: true)

      expect_rendered.to have_link('SAML Group Links', href: group_saml_group_links_path(group))
    end

    it 'has a link to the Webhooks settings page' do
      expect_rendered.to have_link('Webhooks', href: group_hooks_path(group))
    end

    it 'has a link to the Usage Quotas settings page' do
      expect_rendered.to have_link('Usage Quotas', href: group_usage_quotas_path(group))
    end

    it 'has a link to the Billing settings page' do
      allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)

      expect_rendered.to have_link('Billing', href: group_billings_path(group))
    end
  end

  describe 'Administration' do
    before do
      group.add_owner(user)

      stub_licensed_features(usage_quotas: true)

      allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
      allow(group).to receive(:feature_available?).and_call_original
      allow(group).to receive(:feature_available?).with(:group_saml).and_return(true)
      allow(view).to receive(:current_user).and_return(user)

      render
    end

    it 'has a link to the SAML SSO settings page' do
      expect(rendered).to have_link('SAML SSO', href: group_saml_providers_path(group))
    end

    it 'has a link to the Usage Quotas settings page' do
      expect(rendered).to have_link('Usage Quotas', href: group_usage_quotas_path(group))
    end

    it 'has a link to the Billing settings page' do
      expect(rendered).to have_link('Billing', href: group_billings_path(group))
    end
  end
end
