# frozen_string_literal: true

class SamlGroupLink < ApplicationRecord
  include StripAttribute
  belongs_to :group

  strip_attributes! :saml_group_name

  validates :group, :access_level, presence: true
  validates :saml_group_name, presence: true, uniqueness: { scope: [:group_id] }, length: { maximum: 255 }
  validate :access_level_allowed

  scope :by_id_and_group_id, ->(id, group_id) { where(id: id, group_id: group_id) }
  scope :by_saml_group_name, -> (name) { where(saml_group_name: name) }
  scope :by_group_id, ->(group_id) { where(group_id: group_id) }
  scope :preload_group, -> { preload(group: :route) }

  def access_level_allowed
    return unless group
    return if access_level.in?(group.access_level_roles.values)

    errors.add(:access_level, "is invalid")
  end
end
