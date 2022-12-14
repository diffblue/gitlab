# frozen_string_literal: true

class GroupWikiRepository < ApplicationRecord
  include ::Geo::ReplicableModel
  include EachBatch
  include Shardable

  with_replicator Geo::GroupWikiRepositoryReplicator

  belongs_to :group

  validates :group, :disk_path, presence: true, uniqueness: true

  delegate :repository_storage, to: :group

  def self.replicables_for_current_secondary(primary_key_in)
    node = ::Gitlab::Geo.current_node

    replicables = if !node.selective_sync?
                    all
                  elsif node.selective_sync_by_namespaces?
                    group_wiki_repositories_for_selected_namespaces
                  elsif node.selective_sync_by_shards?
                    group_wiki_repositories_for_selected_shards
                  else
                    self.none
                  end

    replicables.primary_key_in(primary_key_in)
  end

  def self.group_wiki_repositories_for_selected_namespaces
    self.joins(:group).where(group_id: ::Gitlab::Geo.current_node.namespaces_for_group_owned_replicables.select(:id))
  end

  def self.group_wiki_repositories_for_selected_shards
    self.for_repository_storage(::Gitlab::Geo.current_node.selective_sync_shards)
  end

  def repository
    group.wiki.repository
  end
end
