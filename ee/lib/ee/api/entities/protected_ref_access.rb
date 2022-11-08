# frozen_string_literal: true

module EE
  module API
    module Entities
      module ProtectedRefAccess
        extend ActiveSupport::Concern

        prepended do
          expose :user_id, documentation: { type: 'integer', example: 1 }
          expose :group_id, documentation: { type: 'integer', example: 1 }
        end
      end
    end
  end
end
