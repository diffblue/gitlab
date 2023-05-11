# frozen_string_literal: true

# Gitlab::Access module
#
# Define allowed roles that can be used
# in GitLab code to determine authorization level
#
module EE
  module Gitlab
    module Access
      extend ActiveSupport::Concern

      MINIMAL_ACCESS_HASH = { "Minimal Access" => ::Gitlab::Access::MINIMAL_ACCESS }.freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        def vulnerability_access_levels
          @vulnerability_access_levels ||= sym_options_with_owner.values_at(:developer, :maintainer, :owner).freeze
        end

        def options_with_minimal_access
          options_with_owner.merge(MINIMAL_ACCESS_HASH)
        end

        def values_with_minimal_access
          options_with_minimal_access.values
        end

        override :human_access
        def human_access(access)
          options_with_minimal_access.key(access)
        end
      end
    end
  end
end
