# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupHook do
  describe 'associations' do
    it { is_expected.to belong_to :group }
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:group_hook, group: create(:group)) }
  end

  describe '#rate_limit', :saas do
    let_it_be(:default_limits) { create(:plan_limits, :free_plan, web_hook_calls: 100) }
    let_it_be(:ultimate_limits) { create(:plan_limits, plan: create(:ultimate_plan), web_hook_calls: 500) }

    let_it_be(:group) { create(:group) }
    let_it_be(:group_ultimate) { create(:group_with_plan, plan: :ultimate_plan) }

    let_it_be(:hook) { create(:group_hook, group: group) }
    let_it_be(:hook_ultimate) { create(:group_hook, group: group_ultimate) }

    it 'returns the default limit for a group without a plan' do
      expect(hook.rate_limit).to be(100)
    end

    it 'returns the configured limit for a group with the Ultimate plan' do
      expect(hook_ultimate.rate_limit).to be(500)
    end
  end

  describe '#parent' do
    it 'returns the associated group' do
      group = build(:group)
      hook = build(:group_hook, group: group)

      expect(hook.parent).to eq(group)
    end
  end

  describe '#application_context' do
    let_it_be(:hook) { build(:group_hook) }

    it 'includes the type and group' do
      expect(hook.application_context).to eq(
        related_class: 'GroupHook',
        namespace: hook.group
      )
    end
  end
end
