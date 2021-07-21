# frozen_string_literal: true

module Dast
  class Profile < ApplicationRecord
    self.table_name = 'dast_profiles'

    belongs_to :project
    belongs_to :dast_site_profile
    belongs_to :dast_scanner_profile

    has_many :secret_variables, through: :dast_site_profile, class_name: 'Dast::SiteProfileSecretVariable'

    has_many :dast_profiles_pipelines, class_name: 'Dast::ProfilesPipeline', foreign_key: :dast_profile_id, inverse_of: :dast_profile
    has_many :ci_pipelines, class_name: 'Ci::Pipeline', through: :dast_profiles_pipelines

    has_many :dast_profile_schedules, class_name: 'Dast::ProfileSchedule', foreign_key: :dast_profile_id, inverse_of: :dast_profile

    validates :description, length: { maximum: 255 }
    validates :name, length: { maximum: 255 }, uniqueness: { scope: :project_id }, presence: true
    validates :branch_name, length: { maximum: 255 }
    validates :project_id, :dast_site_profile_id, :dast_scanner_profile_id, presence: true

    validate :project_ids_match
    validate :branch_name_exists_in_repository
    validate :description_not_nil

    scope :by_project_id, -> (project_id) do
      where(project_id: project_id)
    end

    delegate :secret_ci_variables, to: :dast_site_profile

    def branch
      return unless project.repository.exists?

      Dast::Branch.new(self)
    end

    private

    def project_ids_match
      association_project_id_matches(dast_site_profile)
      association_project_id_matches(dast_scanner_profile)
    end

    def branch_name_exists_in_repository
      return unless branch_name

      unless project.repository.exists?
        errors.add(:project, 'must have a repository')
        return
      end

      unless project.repository.branch_exists?(branch_name)
        errors.add(:branch_name, 'can\'t reference a branch that does not exist')
      end
    end

    def description_not_nil
      errors.add(:description, 'can\'t be nil') if description.nil?
    end

    def association_project_id_matches(association)
      return if association.nil?

      unless project_id == association.project_id
        errors.add(:project_id, "must match #{association.class.underscore}.project_id")
      end
    end
  end
end
