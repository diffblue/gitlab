# frozen_string_literal: true

module EE
  module Namespace
    module Detail
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        scope :not_over_limit_notified, -> { where free_user_cap_over_limit_notified_at: nil }

        scope :scheduled_for_over_limit_check, -> do
          where(next_over_limit_check_at: ..Time.current)
            .or(where(next_over_limit_check_at: nil))
            .order_next_over_limit_check_nulls_first
        end

        scope :order_next_over_limit_check_nulls_first, -> do
          order(arel_table[:next_over_limit_check_at].asc.nulls_first)
        end

        scope :lock_for_over_limit_check, ->(limit, namespace_ids) do
          scheduled_for_over_limit_check
            .where(namespace_id: namespace_ids)
            .limit(limit)
            .lock('FOR UPDATE SKIP LOCKED')
        end
      end
    end
  end
end
