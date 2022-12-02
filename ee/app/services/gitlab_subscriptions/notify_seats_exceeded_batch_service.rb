# frozen_string_literal: true

module GitlabSubscriptions
  class NotifySeatsExceededBatchService
    class << self
      def execute
        iterator.each_batch(of: 100) do |records|
          namespaces = Namespace.where(id: records.select(:namespace_id)) # rubocop:disable CodeReuse/ActiveRecord

          next if namespaces.count == 0

          payload = build_payload(namespaces)
          Gitlab::SubscriptionPortal::Client.send_seat_overage_notification_batch(payload)
        end

        ServiceResponse.success( message: 'Overage notifications sent' )
      end

      private

      def iterator
        @iterator ||= begin
          order = Gitlab::Pagination::Keyset::Order.build(
            [
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: 'max_seats_used_changed_at',
                order_expression: GitlabSubscription.arel_table[:max_seats_used_changed_at].asc,
                distinct: false
              ),
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: 'namespace_id',
                order_expression: GitlabSubscription.arel_table[:namespace_id].asc,
                nullable: :not_nullable,
                distinct: true
              )
            ])

          from = Time.current.beginning_of_day - 1.day
          to = Time.current.beginning_of_day
          scope = GitlabSubscription
            .max_seats_used_changed_between(from: from, to: to)
            .order(order) # rubocop:disable CodeReuse/ActiveRecord

          Gitlab::Pagination::Keyset::Iterator.new(scope: scope)
        end
      end

      def build_payload(namespaces)
        namespaces.map { |namespace| build_namespace(namespace) }
      end

      def build_namespace(namespace)
        {
          glNamespaceId: namespace.id,
          maxSeatsUsed: namespace.gitlab_subscription.max_seats_used,
          groupOwners: build_owners(namespace)
        }
      end

      def build_owners(namespace)
        namespace.owners.map do |owner|
          {
            id: owner.id,
            email: owner&.notification_email_for(namespace),
            fullName: owner.name
          }
        end
      end
    end
  end
end
