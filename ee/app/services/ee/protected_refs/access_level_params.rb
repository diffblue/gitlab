# frozen_string_literal: true

module EE
  module ProtectedRefs
    module AccessLevelParams
      extend ::Gitlab::Utils::Override

      override :access_levels
      def access_levels
        ce_style_access_level + ee_style_access_levels
      end

      private

      override :use_default_access_level?
      def use_default_access_level?(params)
        params[:"allowed_to_#{type}"].blank?
      end

      def ee_style_access_levels
        params[:"allowed_to_#{type}"] || []
      end
    end
  end
end
