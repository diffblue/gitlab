# frozen_string_literal: true

module EE
  module Issuable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include Ai::Model
    end

    def supports_epic?
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
      return false unless supports_escalation?

      ::Gitlab::IncidentManagement.escalation_policies_available?(project)
    end

    def metric_images_available?
      return false unless IssuableMetricImage.available_for?(project)

      supports_metric_images?
    end

    def issuable_resource_links_available?
      supports_resource_links? &&
      ::Gitlab::IncidentManagement.issuable_resource_links_available?(project)
    end

    def supports_sla?
      incident_type_issue?
    end

    def supports_metric_images?
      incident_type_issue?
    end

    def supports_resource_links?
      incident_type_issue?
    end

    override :allows_scoped_labels?
    def allows_scoped_labels?
      resource_parent.licensed_feature_available?(:scoped_labels)
    end

    def supports_iterations?
      false
    end

    def send_to_ai?
      !try(:confidential) && resource_parent.public?
    end

    override :hook_association_changes
    def hook_association_changes(old_associations)
      changes = super

      if supports_escalation? && escalation_status
        current_escalation_policy = escalation_status.policy
        old_escalation_policy = old_associations.fetch(:escalation_policy, current_escalation_policy)

        if old_escalation_policy != current_escalation_policy
          changes[:escalation_policy] = [old_escalation_policy&.hook_attrs, current_escalation_policy&.hook_attrs]
        end
      end

      changes
    end
  end
end
