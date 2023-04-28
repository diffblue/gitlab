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
