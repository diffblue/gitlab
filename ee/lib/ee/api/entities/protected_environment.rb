# frozen_string_literal: true

module EE
  module API
    module Entities
      class ProtectedEnvironment < Grape::Entity
        expose :name
        expose :deploy_access_levels, using: ::API::Entities::ProtectedRefAccess
        expose :required_approval_count
      end
    end
  end
end
