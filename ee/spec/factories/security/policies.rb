# frozen_string_literal: true

FactoryBot.define do
  factory :scan_execution_policy, class: Struct.new(:name, :description, :enabled, :actions, :rules) do
    skip_create

    initialize_with do
      name = attributes[:name]
      description = attributes[:description]
      enabled = attributes[:enabled]
      actions = attributes[:actions]
      rules = attributes[:rules]

      new(name, description, enabled, actions, rules).to_h
    end

    transient do
      agent { 'agent-name' }
      namespaces { %w[namespace-a namespace-b] }
    end

    sequence(:name) { |n| "test-policy-#{n}" }
    description { 'This policy enforces to run DAST for every pipeline within the project' }
    enabled { true }
    rules { [{ type: 'pipeline', branches: %w[master] }] }
    actions { [{ scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }] }

    trait :with_schedule do
      rules { [{ type: 'schedule', branches: %w[master], cadence: '*/15 * * * *' }] }
    end

    trait :with_schedule_and_agent do
      rules { [{ type: 'schedule', agents: { agent.name => { namespaces: namespaces } }, cadence: '30 2 * * *' }] }
      actions { [{ scan: 'container_scanning' }] }
    end
  end

  factory :scan_result_policy,
    class: Struct.new(:name, :description, :enabled, :actions, :rules, :approval_settings) do
    skip_create

    initialize_with do
      name = attributes[:name]
      description = attributes[:description]
      enabled = attributes[:enabled]
      actions = attributes[:actions]
      rules = attributes[:rules]
      approval_settings = attributes[:approval_settings]

      new(name, description, enabled, actions, rules, approval_settings).to_h
    end

    transient do
      branches { ['master'] }
      vulnerability_attributes { {} }
      commits { 'unsigned' }
    end

    sequence(:name) { |n| "test-policy-#{n}" }
    description { 'This policy considers only container scanning and critical severities' }
    enabled { true }
    rules do
      [
        {
          type: 'scan_finding',
          branches: branches,
          scanners: %w[container_scanning],
          vulnerabilities_allowed: 0,
          severity_levels: %w[critical],
          vulnerability_states: %w[detected],
          vulnerability_attributes: vulnerability_attributes
        }
      ]
    end

    actions { [{ type: 'require_approval', approvals_required: 1, user_approvers: %w[admin] }] }
    approval_settings { {} }

    trait :license_finding do
      rules do
        [
          {
            type: 'license_finding',
            branches: branches,
            match_on_inclusion: true,
            license_types: %w[BSD MIT],
            license_states: %w[newly_detected detected]
          }
        ]
      end
    end

    trait :any_merge_request do
      rules do
        [
          {
            type: 'any_merge_request',
            branches: branches,
            commits: commits
          }
        ]
      end
    end

    trait :with_approval_settings do
      approval_settings do
        {
          prevent_approval_by_author: true,
          prevent_approval_by_commit_author: true,
          remove_approvals_with_new_commit: true,
          require_password_to_approve: true,
          block_unprotecting_branches: true
        }
      end
    end
  end

  factory :orchestration_policy_yaml, class: Struct.new(:scan_execution_policy, :scan_result_policy) do
    skip_create

    initialize_with do
      scan_execution_policy = attributes[:scan_execution_policy]
      scan_result_policy = attributes[:scan_result_policy]

      YAML.dump(new(scan_execution_policy, scan_result_policy).to_h.compact.deep_stringify_keys)
    end
  end
end
