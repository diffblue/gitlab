# frozen_string_literal: true

module API
  module Entities
    module ProtectedEnvironments
      class ApprovalRule < Grape::Entity
        expose :user_id
        expose :group_id
        expose :access_level
        expose :humanize, as: :access_level_description
        expose :required_approvals
      end
    end
  end
end
