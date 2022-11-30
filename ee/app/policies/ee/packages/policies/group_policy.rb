# frozen_string_literal: true

module EE
  module Packages
    module Policies
      module GroupPolicy
        extend ActiveSupport::Concern

        prepended do
          include CrudPolicyHelpers

          rule { group.ip_enforcement_prevents_access & ~group.owner }.policy do
            prevent(*create_read_update_admin_destroy(:package))
          end
        end
      end
    end
  end
end
