# frozen_string_literal: true

module GitlabSubscriptions
  class UpcomingReconciliationEntity
    include Gitlab::Utils::StrongMemoize

    COOKIE_KEY_PREFIX = 'hide_upcoming_reconciliation_alert'

    delegate :next_reconciliation_date, to: :upcoming_reconciliation, allow_nil: true

    def initialize(current_user:, namespace: nil)
      @current_user = current_user
      @namespace = namespace
    end

    def cookie_key
      namespace_string = namespace ? "#{namespace.id}_" : ''

      "#{COOKIE_KEY_PREFIX}_#{current_user.id}_#{namespace_string}#{upcoming_reconciliation.next_reconciliation_date}"
    end

    def has_permissions?
      if namespace
        user_can_admin_namespace?
      else
        !!user_is_admin?
      end
    end

    def display_alert?
      !!upcoming_reconciliation&.display_alert? &&
        (namespace.present? || !::License.current&.offline_cloud_license?)
    end

    private

    attr_reader :current_user, :namespace

    def upcoming_reconciliation
      strong_memoize(:upcoming_reconciliation) do
        UpcomingReconciliation.next(namespace&.id)
      end
    end

    def user_is_admin?
      current_user&.can_admin_all_resources?
    end

    def user_can_admin_namespace?
      Ability.allowed?(current_user, :admin_namespace, namespace)
    end
  end
end
