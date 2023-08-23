# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # rubocop:disable Style/Documentation
      module PopulateDenormalizedColumnsForSbomOccurrences
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          operation_name :populate_denormalized_columns_for_sbom_occurrences
        end

        UPDATE_SQL = <<~SQL
          WITH update_data AS (
            SELECT
              sbom_occurrences.id AS occurrence_id,
              sbom_components.name AS component_name,
              sbom_sources.source->'package_manager'->>'name' AS package_manager,
              sbom_sources.source->'input_file'->>'path' AS input_file_path
            FROM
              sbom_occurrences
            INNER JOIN sbom_components ON sbom_components.id = sbom_occurrences.component_id
            LEFT OUTER JOIN sbom_sources ON sbom_sources.id = sbom_occurrences.source_id
            WHERE
              sbom_occurrences.id IN (%{occurrence_ids})
          )
          UPDATE
            sbom_occurrences
          SET
            component_name = update_data.component_name,
            package_manager = update_data.package_manager,
            input_file_path = update_data.input_file_path
          FROM
            update_data
          WHERE
            sbom_occurrences.id = update_data.occurrence_id
        SQL

        override :perform
        def perform
          each_sub_batch do |sub_batch|
            occurrence_ids = sub_batch.pluck(:id).join(', ')
            query = format(UPDATE_SQL, occurrence_ids: occurrence_ids)

            connection.exec_query(query)
          end
        end
      end
    end
  end
end
