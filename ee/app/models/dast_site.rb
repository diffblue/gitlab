# frozen_string_literal: true

class DastSite < ApplicationRecord
  belongs_to :project
  belongs_to :dast_site_validation
  has_many :dast_site_profiles

  validates :url, length: { maximum: 255 }, uniqueness: { scope: :project_id }
  validates :url, addressable_url: true, if: :runner_validation_enabled?
  validates :url, public_url: true, unless: :runner_validation_enabled?

  validates :project_id, presence: true
  validate :dast_site_validation_project_id_fk

  private

  def dast_site_validation_project_id_fk
    return unless dast_site_validation_id

    if project_id != dast_site_validation.project.id
      errors.add(:project_id, 'does not match dast_site_validation.project')
    end
  end

  def runner_validation_enabled?
    ::Feature.enabled?(:dast_runner_site_validation, project, default_enabled: :yaml)
  end
end
