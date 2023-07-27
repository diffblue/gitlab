# frozen_string_literal: true

class GroupWikiRepository < ApplicationRecord
  extend ::Gitlab::Utils::Override
  include ::Geo::ReplicableModel
  include ::Geo::VerifiableModel
  include EachBatch
  include Shardable

  with_replicator Geo::GroupWikiRepositoryReplicator

  belongs_to :group

  has_one :group_wiki_repository_state,
    class_name: 'Geo::GroupWikiRepositoryState',
    inverse_of: :group_wiki_repository,
    autosave: false

  validates :group, :disk_path, presence: true, uniqueness: true

  delegate :repository_storage, to: :group
  delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :group_wiki_repository_state)

  after_save :save_verification_details

  scope :available_verifiables, -> { joins(:group_wiki_repository_state) }

  scope :checksummed, -> {
    joins(:group_wiki_repository_state).where.not(group_wiki_repository_states: { verification_checksum: nil })
  }

  scope :not_checksummed, -> {
    joins(:group_wiki_repository_state).where(group_wiki_repository_states: { verification_checksum: nil })
  }

  scope :with_verification_state, ->(state) {
    joins(:group_wiki_repository_state)
      .where(group_wiki_repository_states: { verification_state: verification_state_value(state) })
  }

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

  override :verification_state_table_class
  def self.verification_state_table_class
    ::Geo::GroupWikiRepositoryState
  end

  def group_wiki_repository_state
    super || build_group_wiki_repository_state
  end

  # Geo checks this method in FrameworkRepositorySyncService to avoid
  # snapshotting repositories using object pools
  def pool_repository
    nil
  end

  def repository
    group.wiki.repository
  end

  def verification_state_object
    group_wiki_repository_state
  end
end
