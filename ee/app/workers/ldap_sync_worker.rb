# frozen_string_literal: true

class LdapSyncWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :authentication_and_authorization
  worker_has_external_dependencies!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    return unless Gitlab::Auth::Ldap::Config.group_sync_enabled?

    Gitlab::AppLogger.info "Performing daily LDAP sync task."
    User.ldap.find_each(batch_size: 100).each do |ldap_user|
      Gitlab::AppLogger.debug "Syncing user #{ldap_user.username}, #{ldap_user.email}"
      # Use the 'update_ldap_group_links_synchronously' option to avoid creating a ton
      # of new Sidekiq jobs all at once.
      Gitlab::Auth::Ldap::Access.allowed?(ldap_user, update_ldap_group_links_synchronously: true)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
