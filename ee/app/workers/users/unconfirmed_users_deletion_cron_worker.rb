# frozen_string_literal: true

module Users
  class UnconfirmedUsersDeletionCronWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue
    include Gitlab::Utils::StrongMemoize

    ITERATIONS = 10
    BATCH_SIZE = 1_000

    idempotent!
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
    feature_category :user_management

    def perform
      return if ::Gitlab::CurrentSettings.email_confirmation_setting_off?
      return unless ::Gitlab::CurrentSettings.delete_unconfirmed_users?
      return unless License.feature_available?(:delete_unconfirmed_users)
      return unless admin_bot_id

      in_lock(self.class.name.underscore, ttl: Gitlab::Utils::ExecutionTracker::MAX_RUNTIME, retries: 0) do
        order = Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'created_at',
            order_expression: User.arel_table[:created_at].desc,
            nullable: :not_nullable,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            order_expression: User.arel_table[:id].desc
          )
        ])

        users = User.unconfirmed_and_created_before(cut_off).select(:created_at, :id, :username).order(order) # rubocop: disable CodeReuse/ActiveRecord
        delete_users(scope: users)
      end
    end

    private

    def delete_users(scope:)
      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope)
      counter = 0

      iterator.each_batch(of: BATCH_SIZE) do |relation|
        counter += 1
        break if counter > ITERATIONS # process no more than 10k records per run

        DeleteUserWorker.bulk_perform_async_with_contexts(
          relation,
          arguments_proc: ->(user) { [admin_bot_id, user.id, { skip_authorization: true }] },
          context_proc: ->(user) { { user: user } }
        )
      end
    end

    def cut_off
      ::Gitlab::CurrentSettings.unconfirmed_users_delete_after_days.days.ago
    end
    strong_memoize_attr :cut_off

    def admin_bot_id
      User.admin_bot&.id
    end
    strong_memoize_attr :admin_bot_id
  end
end
