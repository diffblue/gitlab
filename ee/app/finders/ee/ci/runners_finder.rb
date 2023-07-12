# frozen_string_literal: true

module EE
  module Ci
    module RunnersFinder
      extend ::Gitlab::Utils::Override

      private

      override :allowed_sorts
      def allowed_sorts
        super + ['most_active_desc']
      end

      override :sort!
      def sort!
        if sort_key == 'most_active_desc' && (project || group)
          raise ArgumentError, 'most_active_desc can only be used on instance runners'
        end

        super
      end
    end
  end
end
