# frozen_string_literal: true

module API
  module Entities
    module Deployments
      class Approval < Grape::Entity
        expose :user, using: Entities::UserBasic
        expose :status
      end
    end
  end
end
