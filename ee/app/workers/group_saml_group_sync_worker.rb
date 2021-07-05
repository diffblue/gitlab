# frozen_string_literal: true

class GroupSamlGroupSyncWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include Gitlab::Utils::StrongMemoize

  feature_category :authentication_and_authorization
  tags :exclude_from_kubernetes
  idempotent!

  loggable_arguments 2

  attr_reader :top_level_group, :group_link_ids, :user

  def perform(user_id, top_level_group_id, group_link_ids)
    @top_level_group = Group.find_by_id(top_level_group_id)
    @group_link_ids = group_link_ids
    @user = User.find_by_id(user_id)

    return unless user && feature_available?(top_level_group) && groups_to_sync?

    response = sync_groups

    log_extra_metadata_on_done(:stats, response.payload)
  end

  private

  def feature_available?(group)
    group && group.saml_group_sync_available?
  end

  def groups_to_sync?
    group_links.any? || group_ids_with_any_links.any?
  end

  def sync_groups
    Groups::SyncService.new(
      top_level_group, user,
      group_links: group_links, manage_group_ids: group_ids_with_any_links
    ).execute
  end

  def group_links
    strong_memoize(:group_links) do
      SamlGroupLink.by_id_and_group_id(group_link_ids, group_ids_in_hierarchy).preload_group
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def group_ids_with_any_links
    strong_memoize(:group_ids_with_any_links) do
      SamlGroupLink.by_group_id(group_ids_in_hierarchy).pluck(:group_id).uniq
    end
  end

  def group_ids_in_hierarchy
    top_level_group.self_and_descendants.pluck(:id)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
