# frozen_string_literal: true

module Zoekt
  class IndexedNamespace < ApplicationRecord
    def self.table_name_prefix
      'zoekt_'
    end

    belongs_to :shard, foreign_key: :zoekt_shard_id, inverse_of: :indexed_namespaces
    belongs_to :namespace

    validates :search, inclusion: [true, false]
    validate :only_root_namespaces_can_be_indexed

    scope :recent, -> { order(id: :desc) }
    scope :with_limit, ->(maximum) { limit(maximum) }

    after_commit :index, on: :create
    after_commit :delete_from_index, on: :destroy

    def self.for_shard_and_namespace!(shard:, namespace:)
      find_by!(shard: shard, namespace: namespace)
    end

    def self.find_or_create_for_shard_and_namespace!(shard:, namespace:)
      find_or_create_by!(shard: shard, namespace: namespace)
    end

    def self.enabled_for_project?(project)
      for_project(project).exists?
    end

    def self.enabled_for_namespace?(namespace)
      for_namespace(namespace).exists?
    end

    def self.search_enabled_for_project?(project)
      for_project(project).where(search: true).exists?
    end

    def self.search_enabled_for_namespace?(namespace)
      for_namespace(namespace).where(search: true).exists?
    end

    def self.for_project(project)
      where(namespace: project.root_namespace)
    end

    def self.for_namespace(namespace)
      where(namespace: namespace.root_ancestor)
    end

    private

    def only_root_namespaces_can_be_indexed
      return unless namespace.parent_id.present?

      errors.add(:base, 'Only root namespaces can be indexed')
    end

    def index
      ::Search::Zoekt::NamespaceIndexerWorker.perform_async(namespace_id, :index)
    end

    def delete_from_index
      ::Search::Zoekt::NamespaceIndexerWorker.perform_async(namespace_id, :delete, zoekt_shard_id)
    end
  end
end
