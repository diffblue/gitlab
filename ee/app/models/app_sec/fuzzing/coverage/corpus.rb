# frozen_string_literal: true

module AppSec
  module Fuzzing
    module Coverage
      class Corpus < ApplicationRecord
        self.table_name = 'coverage_fuzzing_corpuses'

        belongs_to :package, class_name: 'Packages::Package'
        belongs_to :user, optional: true
        belongs_to :project

        validate :project_same_as_package_project

        def audit_details
          user&.name
        end

        private

        def project_same_as_package_project
          if package && package.project_id != project_id
            errors.add(:package_id, 'should belong to the associated project')
          end
        end
      end
    end
  end
end
