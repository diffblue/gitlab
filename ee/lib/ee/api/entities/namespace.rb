# frozen_string_literal: true

module EE
  module API
    module Entities
      module Namespace
        extend ActiveSupport::Concern

        prepended do
          can_update_limits = ->(namespace, opts) { ::Ability.allowed?(opts[:current_user], :update_subscription_limit, namespace) }
          can_admin_namespace = ->(namespace, opts) { ::Ability.allowed?(opts[:current_user], :admin_namespace, namespace) }
          has_gitlab_subscription = ->(namespace) { namespace.gitlab_subscription.present? }

          expose :shared_runners_minutes_limit, documentation: { type: 'integer', example: 133 }, if: can_update_limits
          expose :extra_shared_runners_minutes_limit, documentation: { type: 'integer', example: 133 }, if: can_update_limits
          expose :additional_purchased_storage_size, documentation: { type: 'integer', example: 1000 }, if: can_update_limits
          expose :additional_purchased_storage_ends_on, documentation: { type: 'date', example: '2022-06-18' }, if: can_update_limits
          expose :billable_members_count, documentation: { type: 'integer', example: 2 } do |namespace, options|
            namespace.billable_members_count(options[:requested_hosted_plan])
          end
          expose :seats_in_use, documentation: { type: 'integer', example: 5 }, if: has_gitlab_subscription do |namespace, _|
            namespace.gitlab_subscription.seats_in_use
          end
          expose :max_seats_used, documentation: { type: 'integer', example: 100 }, if: has_gitlab_subscription do |namespace, _|
            namespace.gitlab_subscription.max_seats_used
          end
          expose :max_seats_used_changed_at, documentation: { type: 'date', example: '2022-06-18' }, if: has_gitlab_subscription do |namespace, _|
            namespace.gitlab_subscription.max_seats_used_changed_at
          end
          expose :plan, documentation: { type: 'string', example: 'default' }, if: can_admin_namespace do |namespace, _|
            namespace.actual_plan_name
          end
          expose :trial_ends_on, documentation: { type: 'date', example: '2022-06-18' }, if: can_admin_namespace do |namespace, _|
            namespace.trial_ends_on
          end
          expose :trial, documentation: { type: 'boolean' }, if: can_admin_namespace do |namespace, _|
            namespace.trial?
          end
        end
      end
    end
  end
end
