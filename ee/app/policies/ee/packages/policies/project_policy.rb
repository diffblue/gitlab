# frozen_string_literal: true

module EE
  module Packages
    module Policies
      module ProjectPolicy
        extend ActiveSupport::Concern

        prepended do
          include CrudPolicyHelpers

          rule { project.ip_enforcement_prevents_access & ~admin & ~auditor }.policy do
            prevent(*create_read_update_admin_destroy(:package))
          end
        end
      end
    end
  end
end
