# frozen_string_literal: true

module AppSec
  module Fuzzing
    module Coverage
      class Corpus < ApplicationRecord
        self.table_name = 'coverage_fuzzing_corpuses'

        ACCEPTED_FORMATS = %w(.zip).freeze

        belongs_to :package, class_name: 'Packages::Package'
        belongs_to :user, optional: true
        belongs_to :project

        validate :project_same_as_package_project
        validate :package_with_package_file
        validate :validate_file_format

        validates :package_id, uniqueness: true

        scope :by_project_id_and_status_hidden, -> (project_id) do
          joins(:package).where(package: { project_id: project_id, status: :hidden })
        end

        def audit_details
          user&.name
        end

        private

        def project_same_as_package_project
          if package && package.project_id != project_id
            errors.add(:package_id, 'should belong to the associated project')
          end
        end

        def package_with_package_file
          unless latest_package_file
            errors.add(:package_id, 'should have an associated package file')
          end
        end

        def validate_file_format
          return unless latest_package_file

          unless ACCEPTED_FORMATS.include? File.extname(latest_package_file.file_name)
            errors.add(:package_id, 'format is not supported')
          end
        end

        # Currently we are only supporting one package_file per package for a corpus model.
        def latest_package_file
          @package_file ||= package.package_files.last
        end
      end
    end
  end
end
