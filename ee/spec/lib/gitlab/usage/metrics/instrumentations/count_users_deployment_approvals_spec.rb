# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersDeploymentApprovals do
  let_it_be(:user) { create(:user) }
  let_it_be(:deployment_approval) { create(:deployment_approval, user: user) }
  let_it_be(:deployment_approval2) { create(:deployment_approval, user: user) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT(DISTINCT "deployment_approvals"."user_id") FROM "deployment_approvals"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
