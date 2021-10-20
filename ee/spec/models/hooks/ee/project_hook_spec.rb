# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ProjectHook do
  describe '#rate_limit', :saas do
    let_it_be(:default_limits) { create(:plan_limits, :free_plan, web_hook_calls: 100) }
    let_it_be(:ultimate_limits) { create(:plan_limits, plan: create(:ultimate_plan), web_hook_calls: 500) }

    let_it_be(:group) { create(:group) }
    let_it_be(:group_ultimate) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_ultimate) { create(:project, group: group_ultimate) }

    let_it_be(:hook) { create(:project_hook, project: project) }
    let_it_be(:hook_ultimate) { create(:project_hook, project: project_ultimate) }

    it 'returns the default limit for a project without a plan' do
      expect(hook.rate_limit).to be(100)
    end

    it 'returns the configured limit for a project with the Ultimate plan' do
      expect(hook_ultimate.rate_limit).to be(500)
    end
  end
end
