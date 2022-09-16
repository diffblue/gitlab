# frozen_string_literal: true

module EE
  module API
    module Entities
      class MemberRole < Grape::Entity
        expose :id
        expose :namespace_id, as: :group_id
        expose :base_access_level
        expose :download_code
      end
    end
  end
end
