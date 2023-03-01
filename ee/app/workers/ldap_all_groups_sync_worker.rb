# frozen_string_literal: true

class LdapAllGroupsSyncWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :system_access
  worker_has_external_dependencies!

  def perform
    return unless Gitlab::Auth::Ldap::Config.group_sync_enabled?

    logger.info 'Started LDAP group sync'
    EE::Gitlab::Auth::Ldap::Sync::Groups.execute
    logger.info 'Finished LDAP group sync'
  end
end
