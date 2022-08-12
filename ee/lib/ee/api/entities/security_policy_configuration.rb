# frozen_string_literal: true

module EE
  module API
    module Entities
      class SecurityPolicyConfiguration < Grape::Entity
        expose :cadence
        expose :namespaces
        expose :updated_at do |policy|
          policy[:config].policy_last_updated_at.to_datetime.to_s
        end
      end
    end
  end
end
