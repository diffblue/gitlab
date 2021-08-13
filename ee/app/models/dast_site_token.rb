# frozen_string_literal: true

class DastSiteToken < ApplicationRecord
  belongs_to :project

  validates :project_id, presence: true
  validates :token, length: { maximum: 255 }, presence: true, uniqueness: true
  validates :url, length: { maximum: 255 }, presence: true, public_url: true, uniqueness: { scope: :project_id }

  def dast_site
    @dast_site ||= DastSite.find_by(project_id: project.id, url: url)
  end
end
