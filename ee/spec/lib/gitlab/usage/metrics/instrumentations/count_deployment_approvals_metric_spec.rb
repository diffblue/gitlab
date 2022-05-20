# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountDeploymentApprovalsMetric do
  context 'for all time frame' do
    let_it_be(:deployment_approvals) { create_list(:deployment_approval, 2) }

    let(:expected_value) { 2 }
    let(:expected_query) { 'SELECT COUNT("deployment_approvals"."id") FROM "deployment_approvals"' }

    it_behaves_like 'a correct instrumented metric value and query', time_frame: 'all'
  end

  context 'for 28d time frame' do
    let_it_be(:old_deployment_approval) { create(:deployment_approval, created_at: 30.days.ago) }
    let_it_be(:deployment_approvals) { create_list(:deployment_approval, 2, created_at: 2.days.ago) }

    let(:start) { 30.days.ago.to_s(:db) }
    let(:finish) { 2.days.ago.to_s(:db) }

    let(:expected_value) { 2 }
    let(:expected_query) do
      "SELECT COUNT(\"deployment_approvals\".\"id\") FROM \"deployment_approvals\"" \
      " WHERE \"deployment_approvals\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d'
  end
end
