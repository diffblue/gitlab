# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestOccurrences < Base
        include Gitlab::Ingestion::BulkInsertableTask
        include Gitlab::Utils::StrongMemoize

        self.model = Sbom::Occurrence
        self.unique_by = :uuid
        self.uses = :id

        private

        def after_ingest
          return_data.each_with_index do |occurrence_id, index|
            occurrence_maps[index].occurrence_id = occurrence_id
          end
        end

        def attributes
          occurrence_maps.uniq! { |occurrence_map| uuid(occurrence_map) }
          occurrence_maps.map do |occurrence_map|
            {
              project_id: pipeline.project.id,
              pipeline_id: pipeline.id,
              component_id: occurrence_map.component_id,
              component_version_id: occurrence_map.component_version_id,
              source_id: occurrence_map.source_id,
              commit_sha: pipeline.sha,
              uuid: uuid(occurrence_map),
              package_manager: occurrence_map.packager,
              input_file_path: occurrence_map.input_file_path,
              component_name: occurrence_map.name
            }.tap do |attrs|
              if Feature.enabled?(:ingest_sbom_licenses, pipeline.project)
                attrs[:licenses] = licenses.fetch(occurrence_map.report_component, [])
              end
            end
          end
        end

        def uuid(occurrence_map)
          uuid_attributes = occurrence_map.to_h.slice(
            :component_id,
            :component_version_id,
            :source_id
          ).merge(project_id: pipeline.project.id)

          ::Sbom::OccurrenceUUID.generate(**uuid_attributes)
        end

        def licenses
          Licenses.new(pipeline.project, occurrence_maps)
        end
        strong_memoize_attr :licenses

        # This can be deleted after https://gitlab.com/gitlab-org/gitlab/-/issues/370013
        class Licenses
          include Gitlab::Utils::StrongMemoize

          attr_reader :project, :components

          def initialize(project, occurrence_maps)
            @project = project
            @components = occurrence_maps.filter_map do |occurrence_map|
              next if occurrence_map.report_component.purl.blank?

              Hashie::Mash.new(occurrence_map.to_h.slice(
                :name,
                :purl_type,
                :version
              ).merge(path: occurrence_map.input_file_path))
            end
          end

          def fetch(report_component, default = [])
            licenses.fetch(report_component.key, default)
          end

          private

          def licenses
            finder = Gitlab::LicenseScanning::PackageLicenses.new(
              components: components
            )
            finder.fetch.each_with_object({}) do |result, hash|
              licenses = result
                .fetch(:licenses, [])
                .filter_map { |license| map_from(license) }
                .sort_by { |license| license[:spdx_identifier] }
              hash[key_for(result)] = licenses if licenses.present?
            end
          end
          strong_memoize_attr :licenses

          def map_from(license)
            return if license[:spdx_identifier] == "unknown"

            license.slice(:name, :spdx_identifier, :url)
          end

          def key_for(result)
            [result.name, result.version, result.purl_type]
          end
        end
      end
    end
  end
end
