# frozen_string_literal: true
module EE
  module Gitlab
    module HookData
      module IssueBuilder
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        EE_SAFE_HOOK_RELATIONS = %i[
          escalation_policy
        ].freeze

        EE_SAFE_HOOK_ATTRIBUTES = %i[
          weight
          health_status
        ].freeze

        override :build
        def build
          attrs = super

          if issue.escalation_policies_available? && issue.escalation_status
            attrs[:escalation_policy] = issue.escalation_status.policy&.hook_attrs
          end

          attrs
        end

        class_methods do
          extend ::Gitlab::Utils::Override

          override :safe_hook_relations
          def safe_hook_relations
            super + EE_SAFE_HOOK_RELATIONS
          end

          override :safe_hook_attributes
          def safe_hook_attributes
            super + EE_SAFE_HOOK_ATTRIBUTES
          end
        end
      end
    end
  end
end
