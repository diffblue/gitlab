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

    sequence(:name) { |n| "test-policy-#{n}" }
    description { 'This policy enforces to run DAST for every pipeline within the project' }
    enabled { true }
    rules { [{ type: 'pipeline', branches: %w[production] }] }
    actions { [{ scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }] }

    trait :with_schedule do
      rules { [{ type: 'schedule', branches: %w[production], cadence: '*/15 * * * *' }] }
    end
  end

  factory :scan_execution_policy_yaml, class: Struct.new(:scan_execution_policy) do
    skip_create

    initialize_with do
      policies = attributes[:policies]

      YAML.dump(new(policies).to_h.deep_stringify_keys)
    end
  end
end
