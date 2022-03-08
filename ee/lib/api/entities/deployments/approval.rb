# frozen_string_literal: true

module API
  module Entities
    module Deployments
      class Approval < Grape::Entity
        expose :user, using: Entities::UserBasic
        expose :status
        expose :created_at
        expose :comment
      end
    end
  end
end
