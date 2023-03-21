# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SecurityOrchestration::ScanResultPolicyResolver do
  include GraphqlHelpers

  include_context 'orchestration policy context'

  let(:policy) { build(:scan_result_policy, name: 'Require security approvals') }
  let(:policy_yaml) { build(:orchestration_policy_yaml, scan_result_policy: [policy]) }
  let(:expected_resolved) do
    [
      {
        name: 'Require security approvals',
        description: 'This policy considers only container scanning and critical severities',
        enabled: true,
        yaml: YAML.dump(policy.deep_stringify_keys),
        updated_at: policy_last_updated_at,
        user_approvers: [],
        group_approvers: [],
        role_approvers: [],
        source: {
          inherited: false,
          namespace: nil,
          project: project
        }
      }
    ]
  end

  subject(:resolve_scan_policies) { resolve(described_class, obj: project, ctx: { current_user: user }) }

  it_behaves_like 'as an orchestration policy'
end
