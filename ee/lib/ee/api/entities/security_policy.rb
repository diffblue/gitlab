# frozen_string_literal: true

module EE
  module API
    module Entities
      class SecurityPolicy < Grape::Entity
        POLICY_YAML_ATTRIBUTES = %i[name description enabled actions rules].freeze

        expose :name
        expose :description
        expose :enabled
        expose :yaml do |policy|
          YAML.dump(policy.slice(*POLICY_YAML_ATTRIBUTES).deep_stringify_keys)
        end
        expose :updated_at do |policy|
          policy[:config].policy_last_updated_at.to_datetime.to_s
        end
      end
    end
  end
end
