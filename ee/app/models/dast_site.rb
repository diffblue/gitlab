# frozen_string_literal: true

class DastSite < ApplicationRecord
  include AppSec::Dast::UrlAddressable

  belongs_to :project
  belongs_to :dast_site_validation
  has_many :dast_site_profiles

  validates :url, length: { maximum: 255 }, uniqueness: { scope: :project_id }

  validates :project_id, presence: true
  validate :dast_site_validation_project_id_fk

  after_destroy :cleanup_dast_site_token

  private

  def cleanup_dast_site_token
    DastSiteToken.where(project_id: project.id, url: url).delete_all
  end

  def dast_site_validation_project_id_fk
    return unless dast_site_validation_id

    if project_id != dast_site_validation.project.id
      errors.add(:project_id, _('does not match dast_site_validation.project'))
    end
  end
end
