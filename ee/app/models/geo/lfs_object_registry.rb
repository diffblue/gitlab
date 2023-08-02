# frozen_string_literal: true

class Geo::LfsObjectRegistry < Geo::BaseRegistry
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry

  MODEL_CLASS = ::LfsObject
  MODEL_FOREIGN_KEY = :lfs_object_id

  belongs_to :lfs_object, class_name: 'LfsObject'

  scope :for_synced_lfs_objects, ->(lfs_object_ids) { synced.where(lfs_object_id: lfs_object_ids) }

  # @return [Boolean] true if all given oids are synced
  def self.oids_synced?(oids)
    unique_oids = oids.uniq
    lfs_object_ids = ::LfsObject.for_oids(unique_oids).pluck_primary_key

    return false if lfs_object_ids.size < unique_oids.size

    synced_ids = for_synced_lfs_objects(lfs_object_ids).pluck(:lfs_object_id)
    (lfs_object_ids - synced_ids).empty?
  end
end
