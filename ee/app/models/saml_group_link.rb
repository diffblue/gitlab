# frozen_string_literal: true

class SamlGroupLink < ApplicationRecord
  belongs_to :group

  enum access_level: ::Gitlab::Access.options_with_owner

  before_validation :strip_whitespace_from_saml_group_name

  validates :group, :access_level, presence: true
  validates :saml_group_name, presence: true, uniqueness: { scope: [:group_id] }, length: { maximum: 255 }

  scope :by_id_and_group_id, ->(id, group_id) { where(id: id, group_id: group_id) }
  scope :by_saml_group_name, -> (name) { where(saml_group_name: name) }
  scope :by_group_id, ->(group_id) { where(group_id: group_id) }
  scope :preload_group, -> { preload(group: :route) }

  def strip_whitespace_from_saml_group_name
    saml_group_name.strip!
  end

end
