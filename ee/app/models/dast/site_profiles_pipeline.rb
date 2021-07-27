# frozen_string_literal: true

module Dast
  class SiteProfilesPipeline < ApplicationRecord
    extend SuppressCompositePrimaryKeyWarning

    self.table_name = 'dast_site_profiles_pipelines'

    belongs_to :ci_pipeline, class_name: 'Ci::Pipeline', optional: false
    belongs_to :dast_site_profile, class_name: 'DastSiteProfile', optional: false

    validates :ci_pipeline_id, :dast_site_profile_id, presence: true

    validate :project_ids_match

    private

    def project_ids_match
      return if ci_pipeline.nil? || dast_site_profile.nil?

      unless ci_pipeline.project_id == dast_site_profile.project_id
        errors.add(:ci_pipeline_id, 'project_id must match dast_site_profile.project_id')
      end
    end
  end
end
