# frozen_string_literal: true

module IncidentManagement
  module EscalationPolicies
    class UpdateService < EscalationPolicies::BaseService
      include Gitlab::Utils::StrongMemoize

      # @param escalation_policy [IncidentManagement::EscalationPolicy]
      # @param current_user [User]
      # @param params [Hash]
      # @option params [String] name
      # @option params [String] description
      # @option params [Array<Hash>] rules_attributes
      #                              The attributes of the full set of
      #                              the policy's expected escalation rules.
      # @option params[:rules_attributes] [IncidentManagement::OncallSchedule] oncall_schedule
      # @option params[:rules_attributes] [Integer] elapsed_time_seconds
      # @option params[:rules_attributes] [String, Integer, Symbol] status
      def initialize(escalation_policy, current_user, params)
        super(project: escalation_policy.project, current_user: current_user, params: params)

        @escalation_policy = escalation_policy
      end

      def execute
        return error_no_permissions unless allowed?
        return error_no_rules if empty_rules?
        return error_too_many_rules if too_many_rules?
        return error_bad_schedules if invalid_schedules?
        return error_user_without_permission if users_without_permissions?

        reconcile_rules!

        if escalation_policy.update(params)
          success(escalation_policy)
        else
          error_in_save(escalation_policy)
        end
      end

      private

      attr_reader :escalation_policy

      def empty_rules?
        params[:rules_attributes] && params[:rules_attributes].empty?
      end

      # Replaces rules params with records for existing rules,
      # creates records for new rules, and marks appropriate
      # rule records for removal. Records are not actually
      # deleted as there may be pending escalations for the rule.
      def reconcile_rules!
        return unless expected_rules_by_uniq_id.present?

        update_existing_rules!

        params[:rules] = expected_rules_by_uniq_id.merge(existing_rules_by_uniq_id).values
      end

      # Prepares existing rules to be removed or un-removed
      # based on whether they're included in the input params
      def update_existing_rules!
        existing_rules_by_uniq_id.each do |uniq_id, rule|
          rule.is_removed = !expected_rules_by_uniq_id.key?(uniq_id)
        end
      end

      # @return [Hash<Array, IncidentManagement::EscalationRule>]
      def existing_rules_by_uniq_id
        strong_memoize(:existing_rules_by_uniq_id) do
          escalation_policy.rules.index_by { |rule| unique_id(rule) }
        end
      end

      # @return [Hash<Array, IncidentManagement::EscalationRule>]
      def expected_rules_by_uniq_id
        strong_memoize(:expected_rules_by_uniq_id) do
          params.delete(:rules_attributes).to_h do |attrs|
            rule = ::IncidentManagement::EscalationRule.new(**attrs)

            [unique_id(rule), rule]
          end
        end
      end

      def unique_id(rule)
        rule.slice(:oncall_schedule_id, :user_id, :elapsed_time_seconds, :status)
      end
    end
  end
end
