# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsHelper do
  using RSpec::Parameterized::TableSyntax

  let(:owner) { create(:user, group_view: :security_dashboard) }
  let(:current_user) { owner }
  let(:group) { create(:group, :private) }

  before do
    allow(helper).to receive(:current_user) { current_user }
    helper.instance_variable_set(:@group, group)

    group.add_owner(owner)
  end

  describe '#group_sidebar_links' do
    before do
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
      allow(helper).to receive(:show_promotions?) { false }
    end

    it 'shows the licensed features when they are available' do
      stub_licensed_features(contribution_analytics: true,
                             group_ci_cd_analytics: true,
                             epics: true)

      expect(helper.group_sidebar_links).to include(:contribution_analytics, :group_ci_cd_analytics, :epics)
    end

    it 'hides the licensed features when they are not available' do
      stub_licensed_features(contribution_analytics: false,
                             group_ci_cd_analytics: false,
                             epics: false)

      expect(helper.group_sidebar_links).not_to include(:contribution_analytics, :group_ci_cd_analytics, :epics)
    end

    context 'when contribution analytics is available' do
      before do
        stub_licensed_features(contribution_analytics: true)
      end

      context 'signed in user is a project member but not a member of the group' do
        let(:current_user) { create(:user) }
        let(:private_project) { create(:project, :private, group: group)}

        it 'hides Contribution Analytics' do
          expect(helper.group_sidebar_links).not_to include(:contribution_analytics)
        end
      end
    end

    context 'when the group_ci_cd_analytics_page feature flag is disabled' do
      before do
        stub_feature_flags(group_ci_cd_analytics_page: false)
      end

      it 'hides CI/CD Analytics' do
        expect(helper.group_sidebar_links).not_to include(:group_ci_cd_analytics)
      end
    end

    context 'when the user does not have permissions to view the CI/CD Analytics page' do
      let(:current_user) { create(:user) }

      before do
        group.add_guest(current_user)
      end

      it 'hides CI/CD Analytics' do
        expect(helper.group_sidebar_links).not_to include(:group_ci_cd_analytics)
      end
    end

    context 'when iterations is available' do
      before do
        stub_licensed_features(iterations: true)
        stub_feature_flags(iteration_cadences: false)
      end

      it 'shows iterations link' do
        expect(helper.group_sidebar_links).to include(:iterations)
      end

      context 'when iteration_cadences is available' do
        before do
          stub_feature_flags(iteration_cadences: true)
        end

        it 'shows iterations link' do
          expect(helper.group_sidebar_links).to include(:iteration_cadences)
        end
      end
    end
  end

  describe '#render_setting_to_allow_project_access_token_creation?' do
    context 'with self-managed' do
      let_it_be(:parent) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent) }

      before do
        parent.add_owner(owner)
        group.add_owner(owner)
      end

      it 'returns true if group is root' do
        expect(helper.render_setting_to_allow_project_access_token_creation?(parent)).to be_truthy
      end

      it 'returns false if group is subgroup' do
        expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to be_falsey
      end
    end

    context 'on .com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'with a free plan' do
        let_it_be(:group) { create(:group) }

        it 'returns false' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to be_falsey
        end
      end

      context 'with a paid plan' do
        let_it_be(:parent) { create(:group_with_plan, plan: :bronze_plan) }
        let_it_be(:group) { create(:group, parent: parent) }

        before do
          parent.add_owner(owner)
        end

        it 'returns true if group is root' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(parent)).to be_truthy
        end

        it 'returns false if group is subgroup' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to be_falsey
        end
      end
    end
  end

  describe '#permanent_deletion_date' do
    let(:date) { 2.days.from_now }

    subject { helper.permanent_deletion_date(date) }

    before do
      stub_application_setting(deletion_adjourned_period: 5)
    end

    it 'returns the sum of the date passed as argument and the deletion_adjourned_period set in application setting' do
      expected_date = date + 5.days

      expect(subject).to eq(expected_date.strftime('%F'))
    end
  end

  describe '#remove_group_message' do
    subject { helper.remove_group_message(group) }

    context 'delayed deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it 'returns the message related to delayed deletion' do
        expect(subject).to include("The contents of this group, its subgroups and projects will be permanently removed after")
      end
    end

    context 'delayed deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it 'returns the message related to permanent deletion' do
        expect(subject).to include("You are going to remove #{group.name}")
        expect(subject).to include("Removed groups CANNOT be restored!")
      end
    end
  end

  describe '#show_discover_group_security?' do
    using RSpec::Parameterized::TableSyntax

    where(
      gitlab_com?: [true, false],
      user?: [true, false],
      security_dashboard_feature_available?: [true, false],
      can_admin_group?: [true, false]
    )

    with_them do
      it 'returns the expected value' do
        allow(helper).to receive(:current_user) { user? ? owner : nil }
        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(group).to receive(:licensed_feature_available?) { security_dashboard_feature_available? }
        allow(helper).to receive(:can?) { can_admin_group? }

        expected_value = user? && gitlab_com? && !security_dashboard_feature_available? && can_admin_group?

        expect(helper.show_discover_group_security?(group)).to eq(expected_value)
      end
    end
  end

  describe '#show_group_activity_analytics?' do
    before do
      stub_licensed_features(group_activity_analytics: feature_available)

      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
    end

    context 'when feature is not available for group' do
      let(:feature_available) { false }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when current user does not have access to the group' do
      let(:feature_available) { true }
      let(:current_user) { create(:user) }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when feature is available and user has access to it' do
      let(:feature_available) { true }

      it 'returns true' do
        expect(helper.show_group_activity_analytics?).to be true
      end
    end
  end

  describe '#show_usage_quotas_in_sidebar?' do
    where(:usage_quotas_feature_available?, :expected) do
      true  | true
      false | false
    end

    with_them do
      it do
        stub_licensed_features(usage_quotas: usage_quotas_feature_available?)

        expect(helper.show_usage_quotas_in_sidebar?).to eq(expected)
      end
    end
  end

  describe '#show_billing_in_sidebar?' do
    where(:should_check_namespace_plan_return_value, :expected) do
      true  | true
      false | false
    end

    with_them do
      it do
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(should_check_namespace_plan_return_value)

        expect(helper.show_billing_in_sidebar?).to eq(expected)
      end
    end
  end

  describe '#show_administration_nav?' do
    context 'when user does not have admin_group permissions' do
      before do
        allow(helper).to receive(:can?).and_return(true)
        allow(helper).to receive(:can?).with(current_user, :admin_group, group).and_return(false)
      end

      it 'returns false' do
        expect(helper.show_administration_nav?(group)).to be false
      end
    end

    context 'when user has admin_group permissions' do
      before do
        allow(helper).to receive(:can?).and_return(false)
        allow(helper).to receive(:can?).with(current_user, :admin_group, group).and_return(true)
      end

      it 'returns true' do
        allow(helper).to receive(:show_saml_in_sidebar?).with(group).and_return(true)

        expect(helper.show_administration_nav?(group)).to be true
      end

      it 'returns false for a subgroup' do
        subgroup = create(:group, :private, parent: group)

        expect(helper.show_administration_nav?(subgroup)).to be false
      end

      context 'when `group_administration_nav_item` feature flag is enabled for another group' do
        let(:another_group) { create(:group) }

        before do
          stub_feature_flags(group_administration_nav_item: another_group)
        end

        it 'returns false' do
          expect(helper.show_administration_nav?(group)).to be false
        end
      end
    end
  end

  describe '#administration_nav_path' do
    context 'when SAML providers feature is available' do
      before do
        allow(helper).to receive(:show_saml_in_sidebar?).with(group).and_return(true)
      end

      it 'returns path to SAML providers' do
        expect(helper.administration_nav_path(group)).to eq(group_saml_providers_path(group))
      end
    end

    context 'when SAML providers feature is not available' do
      before do
        allow(helper).to receive(:show_saml_in_sidebar?).with(group).and_return(false)
      end

      context 'and usage quotas feature is available' do
        before do
          allow(helper).to receive(:show_usage_quotas_in_sidebar?).and_return(true)
        end

        it 'returns path to usage quotas' do
          expect(helper.administration_nav_path(group)).to eq(group_usage_quotas_path(group))
        end
      end

      context 'and usage quotas feature is not available' do
        before do
          allow(helper).to receive(:show_usage_quotas_in_sidebar?).and_return(false)
        end

        context 'and billing feature is available' do
          before do
            allow(helper).to receive(:show_billing_in_sidebar?).and_return(true)
          end

          it 'returns path to billing' do
            expect(helper.administration_nav_path(group)).to eq(group_billings_path(group))
          end
        end
      end
    end
  end

  describe '#show_delayed_project_removal_setting?' do
    before do
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: licensed?)
    end

    where(:licensed?, :result) do
      true  | true
      false | false
    end

    with_them do
      it { expect(helper.show_delayed_project_removal_setting?(group)).to be result }
    end
  end
end
