# frozen_string_literal: true

class DastSiteToken < ApplicationRecord
  include AppSec::Dast::UrlAddressable

  belongs_to :project

  validates :project_id, presence: true
  validates :token, length: { maximum: 255 }, presence: true, uniqueness: true
  validates :url, length: { maximum: 255 }, uniqueness: { scope: :project_id }, presence: true

  def dast_site
    @dast_site ||= DastSite.find_by(project_id: project.id, url: url)
  end
end
