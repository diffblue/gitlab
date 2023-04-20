# frozen_string_literal: true

module Zoekt
  class IndexedNamespace < ApplicationRecord
    def self.table_name_prefix
      'zoekt_'
    end

    belongs_to :shard, foreign_key: :zoekt_shard_id, inverse_of: :indexed_namespaces
    belongs_to :namespace

    validate :only_root_namespaces_can_be_indexed

    scope :recent, -> { order(id: :desc) }
    scope :with_limit, ->(maximum) { limit(maximum) }

    after_commit :index, on: :create

    def self.for_shard_and_namespace!(shard:, namespace:)
      find_by!(shard: shard, namespace: namespace)
    end

    def self.find_or_create_for_shard_and_namespace!(shard:, namespace:)
      find_or_create_by!(shard: shard, namespace: namespace)
    end

    def self.enabled_for_project?(project)
      where(namespace: project.root_namespace).exists?
    end

    def self.enabled_for_namespace?(namespace)
      where(namespace: namespace.root_ancestor).exists?
    end

    private

    def only_root_namespaces_can_be_indexed
      return unless namespace.parent_id.present?

      errors.add(:base, 'Only root namespaces can be indexed')
    end

    def index
      ::Search::Zoekt::NamespaceIndexerWorker.perform_async(namespace_id, :index)
    end
  end
end
