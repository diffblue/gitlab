# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::FeatureDiscoveryMomentsHelper do
  describe '#show_cross_stage_fdm?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:check_namespace_plan?) { true }
    let(:group_is_persisted?) { true }
    let(:group_is_eligible_for_trial?) { true }
    let(:user_can_admin_group?) { true }

    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan?)

      # Doing this to avoid RSpec WARNING for setting expectations on `nil`
      unless group.nil?
        allow(group).to receive(:persisted?).and_return(group_is_persisted?)
        allow(group).to receive(:plan_eligible_for_trial?).and_return(group_is_eligible_for_trial?)
      end

      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).with(user, :admin_group, group).and_return(user_can_admin_group?)
    end

    subject { helper.show_cross_stage_fdm?(group) }

    where(
      :check_namespace_plan?,         # plans
      :group_is_persisted?,           # persist
      :group_is_eligible_for_trial?,  # trial
      :user_can_admin_group?,         # admin
      :expected_result                # result
    ) do
      # plans | persist | trial | admin | result
      true    | true    | true  | true  | true
      false   | true    | true  | true  | false
      true    | false   | true  | true  | false
      true    | true    | false | true  | false
      true    | true    | true  | false | false
    end

    with_them do
      it { is_expected.to eq(expected_result) }
    end

    context 'when group is nil' do
      let(:group) { nil }

      it { is_expected.to eq(false) }
    end
  end

  describe '#cross_stage_fdm_glm_params' do
    subject { helper.cross_stage_fdm_glm_params }

    it { is_expected.to eq({ glm_source: 'gitlab.com', glm_content: 'cross_stage_fdm' }) }
  end

  describe '#cross_stage_fdm_value_statements' do
    it 'provides a collection of data in the expected structure' do
      expect(helper.cross_stage_fdm_value_statements).to all(
        match(
          icon_name: an_instance_of(String),
          title: an_instance_of(String),
          desc: an_instance_of(String)
        )
      )
    end
  end
end
