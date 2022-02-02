# frozen_string_literal: true

module EE
  module API
    module Entities
      module DeploymentExtended
        extend ActiveSupport::Concern

        prepended do
          expose :pending_approval_count
          expose :approvals, using: ::API::Entities::Deployments::Approval
        end
      end
    end
  end
end
