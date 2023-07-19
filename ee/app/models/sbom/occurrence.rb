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

    delegate :name, to: :component
    delegate :version, to: :component_version, allow_nil: true
    delegate :packager, to: :source, allow_nil: true

    scope :order_by_id, -> { order(id: :asc) }

    scope :order_by_component_name, ->(direction) do
      sort_direction = direction&.downcase == 'desc' ? 'desc' : 'asc'
      joins(:component).order("sbom_components.name #{sort_direction}")
    end

    scope :order_by_package_name, ->(direction) do
      sort_direction = direction&.downcase == 'desc' ? 'desc' : 'asc'
      joins(:source).order(Arel.sql("sbom_sources.source->'package_manager'->'name' #{sort_direction}"))
    end

    scope :filter_by_package_managers, ->(package_managers) do
      where(source_id: Sbom::Source.filter_by_package_managers(package_managers).select(:id))
    end

    scope :filter_by_component_names, ->(component_names) do
      joins(:component).where(sbom_components: { name: component_names })
    end

    scope :filter_by_search_with_component_and_group, ->(search, component_id, group) do
      includes(project: :namespace).where(
        source_id: Sbom::Source.select(:id).where("source->'input_file'->>'path' ILIKE ?", sanitize_sql("%#{search}%")),
        component_id: component_id,
        project: group.all_projects)
    end

    scope :with_component, -> { includes(:component) }
    scope :with_source, -> { includes(:source) }
    scope :with_version, -> { includes(:component_version) }

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
