# frozen_string_literal: true

module Zoekt
  class Shard < ApplicationRecord
    def self.table_name_prefix
      'zoekt_'
    end

    has_many :indexed_namespaces, foreign_key: :zoekt_shard_id, inverse_of: :shard

    def self.for_namespace(root_namespace_id:)
      ::Zoekt::Shard.find_by(
        id: ::Zoekt::IndexedNamespace.where(namespace_id: root_namespace_id).select(:zoekt_shard_id)
      )
    end
  end
end
