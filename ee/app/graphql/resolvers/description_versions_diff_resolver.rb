# frozen_string_literal: true

module Resolvers
  class DescriptionVersionsDiffResolver < ::Resolvers::BaseResolver
    include ::Gitlab::Graphql::Authorize::AuthorizeResource

    type GraphQL::Types::String, null: true

    authorize :read_issuable
    authorizes_object!

    argument :version_id,
      ::Types::GlobalIDType[::DescriptionVersion],
      loads: ::Types::DescriptionVersionType,
      as: :version,
      description: 'ID of a previous version to compare. If not specified first previous version is used.',
      required: false

    def resolve(version: nil)
      return unless has_description_diff?(object, version)

      previous_version = description_version(version)
      return unless previous_version

      generate_html_diff(previous_version)
    end

    private

    def has_description_diff?(object, version)
      return false unless object.resource_parent.licensed_feature_available?(:description_diffs)
      return false if version.present? && version.id >= object.id

      true
    end

    def description_version(version)
      return object.previous_version unless version.present?

      object.issuable.description_versions.visible.find(version.id)
    end

    def generate_html_diff(previous_version)
      diff = ::Gitlab::Diff::CharDiff.new(previous_version.description, object.description)
      diff.generate_diff

      diff.to_html
    end
  end
end
