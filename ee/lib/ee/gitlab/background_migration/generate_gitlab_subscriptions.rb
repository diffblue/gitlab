# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module GenerateGitlabSubscriptions
        extend ::Gitlab::Utils::Override

        class Namespace < ActiveRecord::Base
          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled # Disable STI

          scope :with_plan, -> { where.not(plan_id: nil) }
          scope :without_subscription, -> do
            joins("LEFT JOIN gitlab_subscriptions ON namespaces.id = gitlab_subscriptions.namespace_id")
            .where(gitlab_subscriptions: { id: nil })
          end

          def trial_active?
            trial_ends_on.present? && trial_ends_on >= Date.today
          end
        end

        class GitlabSubscription < ActiveRecord::Base
          self.table_name = 'gitlab_subscriptions'
        end

        override :perform
        def perform(start_id, stop_id)
          now = Time.now

          # Some fields like seats or end_date will be properly updated by a script executed
          # from the subscription portal after this MR hits production.
          rows = Namespace
                  .with_plan
                  .without_subscription
                  .where(id: start_id..stop_id)
                  .select(:id, :plan_id, :trial_ends_on, :created_at)
                  .map do |namespace|
                    {
                      namespace_id: namespace.id,
                      hosted_plan_id: namespace.plan_id,
                      trial: namespace.trial_active?,
                      start_date: namespace.created_at.to_date,
                      auto_renew: false,
                      seats: 0,
                      created_at: now,
                      updated_at: now
                    }
                  end

          Gitlab::Database.main.bulk_insert(:gitlab_subscriptions, rows) # rubocop:disable Gitlab/BulkInsert
        end
      end
    end
  end
end
