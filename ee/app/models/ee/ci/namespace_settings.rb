# frozen_string_literal: true

module EE
  # CI::NamespaceSettings EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Namespace` model
  module Ci
    module NamespaceSettings
      extend ::Gitlab::Utils::Override

      override :allow_stale_runner_pruning?
      def allow_stale_runner_pruning?
        return false unless ci_cd_settings

        ci_cd_settings.allow_stale_runner_pruning?
      end

      override :allow_stale_runner_pruning=
      def allow_stale_runner_pruning=(value)
        return if ci_cd_settings.blank? && !value

        ci_cd_settings ||= ::NamespaceCiCdSetting.find_or_initialize_by(namespace_id: id)
        ci_cd_settings.update(allow_stale_runner_pruning: value)
      end
    end
  end
end
