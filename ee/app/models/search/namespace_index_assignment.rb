# frozen_string_literal: true

module Search
  class NamespaceIndexAssignment < ApplicationRecord
    belongs_to :index, foreign_key: :search_index_id, inverse_of: :namespace_index_assignments
    belongs_to :namespace, optional: true

    before_validation :set_namespace_id_hashed
    before_validation :set_namespace_id_non_nullable
    before_validation :set_index_type
    validate :only_root_namespaces_can_be_indexed

    validates_presence_of :search_index_id, :namespace_id

    validates :namespace_id, uniqueness: {
      scope: :index_type, message: 'violates unique constraint between [:namespace_id, :index_type]'
    }
    validates :namespace_id, uniqueness: {
      scope: :search_index_id, message: 'violates unique constraint between [:namespace_id, :search_index_id]'
    }

    def self.assign_index(namespace:, index:)
      safe_find_or_create_by!(namespace: namespace, index_type: index.type) do |record|  # rubocop:disable Performance/ActiveRecordSubtransactionMethods
        record.namespace_id_non_nullable = namespace.id
        record.index = index
      end
    end

    private

    def set_namespace_id_hashed
      self.namespace_id_hashed ||= namespace&.hashed_root_namespace_id
    end

    def set_namespace_id_non_nullable
      self.namespace_id_non_nullable ||= namespace&.id
    end

    def set_index_type
      self.index_type = index&.type if index&.present?
    end

    def only_root_namespaces_can_be_indexed
      return if namespace.nil? || namespace.root?

      errors.add(:base, 'Only root namespaces can be assigned an index')
    end
  end
end
