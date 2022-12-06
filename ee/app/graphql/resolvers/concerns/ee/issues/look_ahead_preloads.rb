# frozen_string_literal: true

module EE
  module Issues
    module LookAheadPreloads
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :preloads
      def preloads
        super.merge(
          {
            sla_due_at: [:issuable_sla],
            metric_images: [:metric_images],
            related_vulnerabilities: :related_vulnerabilities
          }
        )
      end
    end
  end
end
