# frozen_string_literal: true

module API
  module Entities
    class ScimIdentity < Grape::Entity
      expose :extern_uid
      expose :group_id
      expose :active
    end
  end
end
