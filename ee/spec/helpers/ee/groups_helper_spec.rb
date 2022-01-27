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

    context 'on .com', :saas do
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

      context 'group is already marked for deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: Date.current)
        end

        it 'returns the message related to permanent deletion' do
          expect(subject).to include("You are going to remove #{group.name}")
          expect(subject).to include("Removed groups CANNOT be restored!")
        end
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

  describe '#immediately_remove_group_message' do
    subject { helper.immediately_remove_group_message(group) }

    it 'returns the message related to immediate deletion' do
      expect(subject).to match(/permanently remove.*#{group.path}.*immediately/)
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

  describe '#show_product_purchase_success_alert?' do
    describe 'when purchased_product is present' do
      before do
        allow(controller).to receive(:params) { { purchased_product: product } }
      end

      where(:product, :result) do
        'product' | true
        ''        | false
        nil       | false
      end

      with_them do
        it { expect(helper.show_product_purchase_success_alert?).to be result }
      end
    end

    describe 'when purchased_product is not present' do
      it { expect(helper.show_product_purchase_success_alert?).to be false }
    end
  end

  describe '#require_verification_for_namespace_creation_enabled?' do
    let(:variant) { :control }

    subject { helper.require_verification_for_namespace_creation_enabled? }

    before do
      stub_experiments(require_verification_for_namespace_creation: variant)
    end

    context 'when in candidate path' do
      let(:variant) { :candidate }

      it { is_expected.to eq(true) }

      context 'when creating a sub-group' do
        before do
          allow(controller).to receive(:params) { { parent_id: 1 } }
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when in control path' do
      it { is_expected.to eq(false) }
    end
  end
end
