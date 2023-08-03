# frozen_string_literal: true

class GroupSamlGroupSyncWorker < SystemAccess::BaseSaasGroupSyncWorker
  include ApplicationWorker
  include Gitlab::Utils::StrongMemoize

  data_consistency :always
  sidekiq_options retry: 3
  feature_category :system_access
  idempotent!

  loggable_arguments 2

  def perform(user_id, top_level_group_id, group_link_ids)
    @top_level_group = Group.find_by_id(top_level_group_id)
    @group_link_ids = group_link_ids
    @user = User.find_by_id(user_id)

    return unless user && feature_available?(top_level_group) && groups_to_sync?

    sync_and_update_default_membership
  end

  private

  attr_reader :group_link_ids

  def feature_available?(group)
    group && group.saml_group_sync_available?
  end

  def groups_to_sync?
    group_links.any? || group_ids_with_any_links.any?
  end

  def group_links
    SamlGroupLink.by_id_and_group_id(group_link_ids, group_ids_in_hierarchy).preload_group
  end
  strong_memoize_attr :group_links
end
