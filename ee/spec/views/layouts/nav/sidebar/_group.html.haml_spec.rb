# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_group' do
  before do
    assign(:group, group)
    allow(view).to receive(:show_trial_status_widget?).and_return(false)
  end

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  describe 'trial status widget', :aggregate_failures do
    using RSpec::Parameterized::TableSyntax

    let(:experiment_key) { :show_trial_status_in_sidebar }
    let(:show_widget) { false }
    let(:experiment_enabled) { false }

    before do
      allow(view).to receive(:show_trial_status_widget?).and_return(show_widget)
      allow(view).to receive(:experiment_enabled?).with(experiment_key, subject: group).and_return(experiment_enabled)
      allow(view).to receive(:record_experiment_group)
      allow(view).to receive(:trial_status_widget_data_attrs)
      allow(view).to receive(:trial_status_popover_data_attrs)
      render
    end

    subject do
      render
      rendered
    end

    shared_examples 'does not render the widget & popover' do
      it 'does not render' do
        is_expected.not_to have_selector '#js-trial-status-widget'
        is_expected.not_to have_selector '#js-trial-status-popover'
      end
    end

    shared_examples 'renders the widget & popover' do
      it 'renders both the widget & popover component initialization elements' do
        is_expected.to have_selector '#js-trial-status-widget'
        is_expected.to have_selector '#js-trial-status-popover'
      end
    end

    shared_examples 'does record experiment subject' do
      it 'records the group as an experiment subject' do
        expect(view).to receive(:record_experiment_group).with(experiment_key, group)

        subject
      end
    end

    shared_examples 'does not record experiment subject' do
      it 'does not record the group as an experiment subject' do
        expect(view).not_to receive(:record_experiment_group)

        subject
      end
    end

    where :show_widget, :experiment_enabled, :examples_to_include do
      true  | true  | ['does record experiment subject', 'renders the widget & popover']
      true  | false | ['does record experiment subject', 'does not render the widget & popover']
      false | true  | ['does not record experiment subject', 'does not render the widget & popover']
      false | false | ['does not record experiment subject', 'does not render the widget & popover']
    end

    with_them do
      params[:examples_to_include].each do |example_set|
        include_examples(example_set)
      end
    end
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

  describe 'DevOps adoption link' do
    let!(:current_user) { create(:user) }

    before do
      group.add_maintainer(current_user)

      allow(view).to receive(:current_user).and_return(current_user)
    end

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

  describe 'contribution analytics tab' do
    let!(:current_user) { create(:user) }

    before do
      group.add_guest(current_user)

      allow(view).to receive(:current_user).and_return(current_user)
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

      context 'we do not show promotions' do
        before do
          allow(LicenseHelper).to receive(:show_promotions?).and_return(false)
        end

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

      it 'is visible when there is no valid license but we show promotions' do
        stub_licensed_features(contribution_analytics: false)

        render

        expect(rendered).to have_text 'Contribution'
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

  describe 'security dashboard tab' do
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

        expect(rendered).to have_link 'Security & Compliance'
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

          expect(rendered).not_to have_link 'Security & Compliance'
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

          expect(rendered).to have_link 'Security & Compliance'
          expect(rendered).to have_link 'Compliance'
        end
      end
    end

    context 'when credentials inventory feature is enabled' do
      shared_examples_for 'Credentials tab is not visible' do
        it 'does not show the `Credentials` tab' do
          render

          expect(rendered).not_to have_link 'Security & Compliance'
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

            expect(rendered).to have_link 'Security & Compliance'
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

          expect(rendered).not_to have_link 'Security & Compliance'
          expect(rendered).not_to have_link 'Audit Events'
        end
      end

      context 'when the user has access to Audit Events' do
        before do
          group.add_owner(user)
          allow(view).to receive(:current_user).and_return(user)
        end

        it 'is visible' do
          render

          expect(rendered).to have_link 'Security & Compliance'
          expect(rendered).to have_link 'Audit Events'
        end
      end
    end

    context 'when security dashboard feature is disabled' do
      let(:group) { create(:group_with_plan, plan: :bronze_plan) }

      it 'is not visible' do
        render

        expect(rendered).not_to have_link 'Security & Compliance'
      end
    end
  end

  describe 'wiki tab' do
    let(:can_read_wiki) { true }

    let_it_be(:current_user) { create(:user) }

    before do
      group.add_guest(current_user)

      allow(view).to receive(:current_user).and_return(current_user)
      allow(view).to receive(:can?).with(current_user, :read_wiki, group).and_return(can_read_wiki)
    end

    describe 'when wiki is available to user' do
      it 'shows the wiki tab with the wiki internal link' do
        render

        expect(rendered).to have_link('Wiki', href: group.wiki.web_url)
      end
    end

    describe 'when wiki is unavailable to user' do
      let(:can_read_wiki) { false }

      it 'does not show the wiki tab' do
        render

        expect(rendered).not_to have_link('Wiki', href: group.wiki.web_url)
      end
    end
  end

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

      context 'with group iterations feature flag enabled' do
        before do
          stub_feature_flags(group_iterations: true)
        end

        it 'is visible' do
          render

          expect(rendered).to have_text 'Iterations'
        end
      end

      context 'with iterations feature flag disabled' do
        before do
          stub_feature_flags(group_iterations: false)
        end

        it 'is not visible' do
          render

          expect(rendered).not_to have_text 'Iterations'
        end
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
