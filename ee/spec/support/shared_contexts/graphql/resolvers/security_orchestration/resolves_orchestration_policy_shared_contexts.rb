# frozen_string_literal: true

RSpec.shared_context 'orchestration policy context' do
  let_it_be(:policy_last_updated_at) { Time.now }
  let_it_be(:project) { create(:project) }
  let_it_be(:policy_management_project) { create(:project) }
  let_it_be(:user) { create(:user) }
end
