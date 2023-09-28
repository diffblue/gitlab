# frozen_string_literal: true

module Sbom
  class Occurrence < ApplicationRecord
    include EachBatch

    belongs_to :component, optional: false
    belongs_to :component_version
    belongs_to :project, optional: false
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :source

    validates :commit_sha, presence: true
    validates :uuid, presence: true, uniqueness: { case_sensitive: false }
    validates :package_manager, length: { maximum: 255 }
    validates :component_name, length: { maximum: 255 }
    validates :input_file_path, length: { maximum: 255 }
    validates :licenses, json_schema: { filename: 'sbom_occurrences-licenses' }

    delegate :name, to: :component
    delegate :purl_type, to: :component
    delegate :component_type, to: :component
    delegate :version, to: :component_version, allow_nil: true
    delegate :packager, to: :source, allow_nil: true

    scope :order_by_id, -> { order(id: :asc) }

    scope :order_by_component_name, ->(direction) do
      order(component_name: direction)
    end

    scope :order_by_package_name, ->(direction) do
      order(package_manager: direction)
    end

    scope :order_by_spdx_identifier, ->(direction, depth: 1) do
      order(Gitlab::Pagination::Keyset::Order.build(
        0.upto(depth).map do |index|
          sql = Arel.sql("(licenses#>'{#{index},spdx_identifier}')::text")
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: "spdx_identifier_#{index}",
            order_expression: direction == "desc" ? sql.desc : sql.asc,
            distinct: false,
            sql_type: 'text'
          )
        end
      ))
    end

    scope :filter_by_package_managers, ->(package_managers) do
      where(package_manager: package_managers)
    end

    scope :filter_by_components, ->(components) do
      where(component: components)
    end

    scope :filter_by_component_names, ->(component_names) do
      where(component_name: component_names)
    end

    scope :filter_by_search_with_component_and_group, ->(search, component_id, group) do
      includes(project: :namespace).where('input_file_path ILIKE ?', "%#{sanitize_sql_like(search.to_s)}%") # rubocop:disable GitlabSecurity/SqlInjection
                                   .where(component_id: component_id, project: group.all_projects)
    end

    scope :with_component, -> { includes(:component) }
    scope :with_source, -> { includes(:source) }
    scope :with_version, -> { includes(:component_version) }
    scope :with_component_source_version_project_and_pipeline, -> do
      includes(:component, :source, :component_version, :project).preload(:pipeline)
    end
    scope :filter_by_non_nil_component_version, -> { where.not(component_version: nil) }
    scope :filter_by_cvs_enabled, -> do
      joins(project: :security_setting)
        .where(project_security_settings: { continuous_vulnerability_scans_enabled: true })
    end

    def location
      {
        blob_path: input_file_blob_path,
        path: source&.input_file_path,
        top_level: false,
        ancestors: nil
      }
    end

    private

    def input_file_blob_path
      return unless source&.input_file_path.present?

      Gitlab::Routing.url_helpers.project_blob_path(project, File.join(commit_sha, source.input_file_path))
    end
  end
end
