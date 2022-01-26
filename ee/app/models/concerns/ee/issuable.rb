# frozen_string_literal: true

module EE
  module Issuable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    def supports_epic?
      false
    end

    def supports_health_status?
      false
    end

    def supports_weight?
      false
    end

    def weight_available?
      supports_weight? && project&.feature_available?(:issue_weights)
    end

    def sla_available?
      return false unless ::IncidentManagement::IncidentSla.available_for?(project)

      supports_sla?
    end

    def escalation_policies_available?
      return false unless ::Gitlab::IncidentManagement.escalation_policies_available?(project)

      supports_escalation?
    end

    def metric_images_available?
      return false unless IssuableMetricImage.available_for?(project)

      supports_metric_images?
    end

    def supports_sla?
      incident?
    end

    def supports_metric_images?
      incident?
    end

    def supports_iterations?
      false
    end
  end
end
