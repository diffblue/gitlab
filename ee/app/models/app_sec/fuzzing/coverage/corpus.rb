# frozen_string_literal: true

module AppSec
  module Fuzzing
    module Coverage
      class Corpus < ApplicationRecord
        self.table_name = 'coverage_fuzzing_corpuses'

        belongs_to :package, class_name: 'Packages::Package'
        belongs_to :user, optional: true
        belongs_to :project
      end
    end
  end
end
