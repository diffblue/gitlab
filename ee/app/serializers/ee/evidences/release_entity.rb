# frozen_string_literal: true

module EE
  module Evidences
    module ReleaseEntity
      extend ActiveSupport::Concern

      prepended do
        expose :report_artifacts,
          using: ::Evidences::BuildArtifactEntity,
          if: -> (release) { release.project.feature_available?(:release_evidence_test_artifacts) } do |_, options|
            options[:report_artifacts]
          end
      end
    end
  end
end
