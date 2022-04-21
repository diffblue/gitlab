# frozen_string_literal: true

module API
  module Entities
    module Deployments
      class ApprovalSummary < Grape::Entity
        expose :rules, using: ::API::Entities::ProtectedEnvironments::ApprovalRuleForSummary
      end
    end
  end
end
