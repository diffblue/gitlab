# frozen_string_literal: true

class LdapGroupSyncWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :authentication_and_authorization
  worker_has_external_dependencies!
  weight 2
  loggable_arguments 0, 1
  tags :exclude_from_gitlab_com

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(group_ids, provider = nil)
    return unless Gitlab::Auth::Ldap::Config.group_sync_enabled?

    groups = Group.where(id: Array(group_ids))

    if provider
      EE::Gitlab::Auth::Ldap::Sync::Proxy.open(provider) do |proxy|
        sync_groups(groups, proxy: proxy)
      end
    else
      sync_groups(groups)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def sync_groups(groups, proxy: nil)
    groups.each { |group| sync_group(group, proxy: proxy) }
  end

  def sync_group(group, proxy: nil)
    logger.info "Started LDAP group sync for group #{group.name} (#{group.id})"

    if proxy
      EE::Gitlab::Auth::Ldap::Sync::Group.execute(group, proxy)
    else
      EE::Gitlab::Auth::Ldap::Sync::Group.execute_all_providers(group)
    end

    logger.info "Finished LDAP group sync for group #{group.name} (#{group.id})"
  end
end
