# frozen_string_literal: true

module Namespaces
  module Storage
    class SubgroupPreEnforcementAlertComponent < ::Namespaces::Storage::PreEnforcementAlertComponent
      private

      def paragraph_1_extra_message
        Kernel.format(
          s_("UsageQuota|The %{strong_start}%{context_name}%{strong_end} group will be affected by this. "),
          strong_tags.merge(context_name: context.name)
        )
      end
    end
  end
end
