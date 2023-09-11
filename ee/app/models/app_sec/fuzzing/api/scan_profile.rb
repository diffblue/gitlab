# frozen_string_literal: true

module AppSec
  module Fuzzing
    module API
      class ScanProfile
        NAMES = %w[Quick-10 Medium-20 Medium-50 Long-100].freeze

        DESCRIPTIONS = {
          'Quick-10' => 'Fuzzing 10 times per parameter',
          'Medium-20' => 'Fuzzing 20 times per parameter',
          'Medium-50' => 'Fuzzing 50 times per parameter',
          'Long-100' => 'Fuzzing 100 times per parameter'
        }.freeze

        attr_reader :description, :name, :project, :yaml

        def initialize(name:, project:, yaml:)
          @description = DESCRIPTIONS[name]
          @name = name
          @project = project
          @yaml = yaml
        end
      end
    end
  end
end
