# frozen_string_literal: true

module Search
  INDEX_PARTITIONING_HASHING_MODULO = 1024

  def self.table_name_prefix
    'search_'
  end

  def self.hash_namespace_id(namespace_id, maximum: INDEX_PARTITIONING_HASHING_MODULO)
    return unless namespace_id.present?

    namespace_id.to_s.hash % maximum
  end
end
