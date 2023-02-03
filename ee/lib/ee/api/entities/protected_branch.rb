# frozen_string_literal: true

module EE
  module API
    module Entities
      module ProtectedBranch
        extend ActiveSupport::Concern

        prepended do
          expose :unprotect_access_levels, using: ::API::Entities::ProtectedRefAccess, documentation: { is_array: true }
          expose :code_owner_approval_required, documentation: { type: 'boolean' }
          expose :inherited, documentation: { type: 'boolean' }
        end
      end
    end
  end
end
