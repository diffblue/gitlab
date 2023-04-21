# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # Class that fixes the POSSIBLE incorrect `max_seats_used`
      # in gitlab_subscriptions table
      module FixIncorrectMaxSeatsUsed
        class FixIncorrectMaxSeatsUsedJsonLogger < ::Gitlab::JsonLogger
          def self.file_name_noext
            'fix_incorrect_max_seats_used_json'
          end
        end

        class Namespace < ActiveRecord::Base
          self.table_name = 'namespaces'

          # disable STI
          self.inheritance_column = nil
        end

        class Plan < ActiveRecord::Base
          self.table_name = 'plans'

          FREE = 'free'
          BRONZE = 'bronze'
          SILVER = 'silver'
          PREMIUM = 'premium'
          GOLD = 'gold'
          ULTIMATE = 'ultimate'
          ULTIMATE_TRIAL = 'ultimate_trial'
          PREMIUM_TRIAL = 'premium_trial'

          PAID_HOSTED_PLANS = [BRONZE, SILVER, PREMIUM, GOLD, ULTIMATE, ULTIMATE_TRIAL, PREMIUM_TRIAL].freeze
        end

        class GitlabSubscription < ActiveRecord::Base
          self.table_name = 'gitlab_subscriptions'

          belongs_to :namespace
          belongs_to :hosted_plan, class_name: 'Plan'
          has_many :gitlab_subscription_histories

          before_update :log_previous_state_for_update
          before_update :reset_seats_for_new_term

          delegate :name, :title, to: :hosted_plan, prefix: :plan, allow_nil: true

          def calculate_seats_owed
            return 0 unless has_a_paid_hosted_plan?

            [0, max_seats_used - seats].max
          end

          def has_a_paid_hosted_plan?(include_trials: false)
            (include_trials || !trial?) &&
              seats > 0 &&
              Plan::PAID_HOSTED_PLANS.include?(plan_name)
          end

          private

          def log_previous_state_for_update
            attrs = self.attributes.merge(self.attributes_in_database)
            log_previous_state_to_history(:gitlab_subscription_updated, attrs)
          end

          def log_previous_state_to_history(change_type, attrs = {})
            attrs['gitlab_subscription_created_at'] = attrs['created_at']
            attrs['gitlab_subscription_updated_at'] = attrs['updated_at']
            attrs['gitlab_subscription_id'] = self.id
            attrs['change_type'] = change_type

            omitted_attrs = %w(id created_at updated_at seats_in_use seats_owed max_seats_used_changed_at last_seat_refresh_at)

            GitlabSubscriptionHistory.create(attrs.except(*omitted_attrs))
          end

          def reset_seats_for_new_term
            return unless new_term?

            self.max_seats_used = attributes['seats_in_use']
            self.seats_owed = calculate_seats_owed
          end

          def new_term?
            persisted? && start_date_changed? && end_date_changed? &&
              (end_date_was.nil? || start_date >= end_date_was)
          end
        end

        class GitlabSubscriptionHistory < ActiveRecord::Base
          self.table_name = 'gitlab_subscription_histories'

          belongs_to :gitlab_subscription
        end

        BATCH_SIZE = 200

        def perform(batch = nil)
          gitlab_subscriptions = if batch == 'batch_2_for_start_date_before_02_aug_2021'
                                   eligible_gitlab_subscriptions_batch_2
                                 else
                                   eligible_gitlab_subscriptions
                                 end

          gitlab_subscriptions.find_each(batch_size: BATCH_SIZE) do |gs|
            gs_histories = gs.gitlab_subscription_histories.to_a.sort_by { |gh| gh.id }
            gs_histories << gs

            last_new_term_index = find_last_new_term_index(gs_histories)
            next unless last_new_term_index

            reset(gs) if requires_reset(gs, gs_histories, last_new_term_index)
          end
        end

        private

        def file_logger
          @file_logger ||= FixIncorrectMaxSeatsUsedJsonLogger.build
        end

        def reset(gs)
          identified_subscription = gs.attributes.merge(namespace_path: gs.namespace.path)

          gs.max_seats_used = gs.seats_in_use
          gs.seats_owed = gs.calculate_seats_owed

          changes = gs.changes
          success = gs.save

          file_logger.info({ identified_subscription: identified_subscription, changes: changes, success: success })
        end

        def new_term?(gs_histories, index)
          new_start_date = gs_histories[index].start_date
          previous_end_date = gs_histories[index - 1].end_date

          return false if new_start_date.nil?

          return true if previous_end_date.nil? || new_start_date >= previous_end_date

          false
        end

        def find_last_new_term_index(gs_histories)
          return if gs_histories.size < 2

          # to find the latest new subscription term
          index = gs_histories.size - 1
          while index > 0
            return index if new_term?(gs_histories, index)

            index -= 1
          end
        end

        def requires_reset(gs, gs_histories, last_new_term_index)
          new_term_max_seats_used = gs_histories[last_new_term_index].max_seats_used
          previous_max_seats_used = gs_histories[last_new_term_index - 1].max_seats_used

          # New term `max_seats_used` started from `0`. No need to reset
          return false if new_term_max_seats_used == 0

          # New term and previous term value differ, we assume the value was already reset
          return false if new_term_max_seats_used != previous_max_seats_used

          # `max_seats_used` ever increased after the new term start. No need to reset
          return false if new_term_max_seats_used < gs.max_seats_used

          # Current gitlab_subscription `seats_in_use` is equal to or larger. No need to reset
          return false if new_term_max_seats_used <= gs.seats_in_use

          true
        end

        def eligible_gitlab_subscriptions
          # Only search subscriptions with `start_date` in range `['2021-08-02', '2021-11-20']` because:
          #   - for subscriptions with `start_date < '2021-08-02'`, we do not enable QSR(Quarterly Subscription Reconciliation)
          #   - for subscriptions with `start_date > '2021-11-20'`, they should not have such issue
          #     because the MR https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73078 was merged on `2021-11-09`.
          #     All rails nodes should have deployed new merged code within 10 days.
          #
          # Only need to check if max_seats_used is not 0
          # Only need to check if max_seats_used > seats_in_use
          # Only need to check if max_seats_used > seats (zuora subscription quantity)

          GitlabSubscription.preload(:namespace, :hosted_plan, :gitlab_subscription_histories)
            .where('gitlab_subscriptions.start_date >= ?', Date.parse('2021-08-02'))
            .where('gitlab_subscriptions.start_date <= ?', Date.parse('2021-11-20'))
            .where.not(max_seats_used: 0)
            .where('gitlab_subscriptions.max_seats_used > gitlab_subscriptions.seats_in_use')
            .where('gitlab_subscriptions.max_seats_used > gitlab_subscriptions.seats')
        end

        def eligible_gitlab_subscriptions_batch_2
          # Only search subscriptions with `start_date < '2021-08-02'`
          # Only need to check if max_seats_used is not 0
          # Only need to check if max_seats_used > seats_in_use
          # Only need to check if max_seats_used > seats (zuora subscription quantity)

          GitlabSubscription.preload(:namespace, :hosted_plan, :gitlab_subscription_histories)
            .where('gitlab_subscriptions.start_date < ?', Date.parse('2021-08-02'))
            .where.not(max_seats_used: 0)
            .where('gitlab_subscriptions.max_seats_used > gitlab_subscriptions.seats_in_use')
            .where('gitlab_subscriptions.max_seats_used > gitlab_subscriptions.seats')
        end
      end
    end
  end
end
