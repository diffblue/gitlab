# frozen_string_literal: true

module EE
  module API
    module Entities
      class IdentityDetail < Grape::Entity
        expose :extern_uid
        expose :user_id
        expose :active, if: ->(identity) { identity.has_attribute?(:active) }
      end
    end
  end
end
