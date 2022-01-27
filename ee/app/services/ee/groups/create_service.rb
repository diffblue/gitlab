# frozen_string_literal: true

module EE
  module Groups
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super.tap do |group|
          next unless group&.persisted?

          log_audit_event
          create_push_rule_for_group
        end
      end

      private

      override :after_build_hook
      def after_build_hook(group, params)
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        group.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
      end

      override :after_create_hook
      def after_create_hook
        super

        if group.persisted? && create_event
          ::Groups::CreateEventWorker.perform_async(group.id, current_user.id, :created)
        end

        track_verification_experiment_conversion
      end

      override :remove_unallowed_params
      def remove_unallowed_params
        unless current_user&.admin?
          params.delete(:shared_runners_minutes_limit)
          params.delete(:extra_shared_runners_minutes_limit)
          params.delete(:delayed_project_removal)
        end

        super
      end

      def log_audit_event
        ::AuditEventService.new(
          current_user,
          group,
          action: :create
        ).for_group.security_event
      end

      def create_push_rule_for_group
        return unless group.licensed_feature_available?(:push_rules)

        push_rule = group.predefined_push_rule
        return unless push_rule

        attributes = push_rule.attributes.symbolize_keys.except(:is_sample, :id)
        PushRule.create(attributes.compact).tap do |push_rule|
          group.update(push_rule: push_rule)
        end
      end

      def track_verification_experiment_conversion
        return unless group.persisted?
        return unless group.root?

        experiment(:require_verification_for_namespace_creation, user: current_user).track(:finish_create_group, namespace: group)
      end
    end
  end
end
