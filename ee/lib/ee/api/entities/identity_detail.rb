# frozen_string_literal: true

module EE
  module API
    module Entities
      class IdentityDetail < Grape::Entity
        expose :extern_uid
        expose :user_id
      end
    end
  end
end
