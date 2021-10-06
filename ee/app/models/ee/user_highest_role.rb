# frozen_string_literal: true

module EE
  module UserHighestRole
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :allowed_values
      def allowed_values
        ::Gitlab::Access.values_with_minimal_access
      end
    end
  end
end
