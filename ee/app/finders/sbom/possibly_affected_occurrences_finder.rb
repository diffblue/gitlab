# frozen_string_literal: true

module Sbom
  class PossiblyAffectedOccurrencesFinder
    include Gitlab::Utils::StrongMemoize

    BATCH_SIZE = 100

    def initialize(purl_type:, package_name:)
      @purl_type = purl_type
      @package_name = package_name
    end

    def execute_in_batches(of: BATCH_SIZE)
      return unless component_id

      Sbom::Occurrence.filter_by_components(component_id).each_batch(of: of) do |batch|
        yield batch
          .with_component_source_version_project_and_pipeline
          .filter_by_non_nil_component_version
          .filter_by_cvs_enabled
      end
    end

    private

    attr_reader :package_name, :purl_type

    def component_id
      Sbom::Component
        .libraries
        .by_purl_type_and_name(purl_type, package_name)
        .select(:id)
        .first
    end
    strong_memoize_attr :component_id
  end
end
