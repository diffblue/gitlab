# frozen_string_literal: true

module EE
  module Types
    module DescriptionVersionType
      extend ActiveSupport::Concern

      DEPRECATION_REASON = 'For backwards compatibility with REST API version and to be removed in a next iteration'

      include ::Gitlab::Routing.url_helpers
      include ::GitlabRoutingHelper
      include ::NotesHelper

      prepended do
        field :diff,
          null: true,
          description: 'Description diff between versions.',
          resolver: ::Resolvers::DescriptionVersionsDiffResolver

        # These fields are added for backward compatibility with previous REST API endpoint.
        # This is to be removed once we move over to using GraphQL diff field.
        # see https://gitlab.com/gitlab-org/gitlab/-/issues/385535
        field :diff_path, GraphQL::Types::String,
          null: true,
          description: 'Web path to description version associated to the note metadata.',
          deprecated: { reason: DEPRECATION_REASON, milestone: '15.7' }
        field :delete_path, GraphQL::Types::String,
          null: true,
          description: 'Web path to delete description version associated to the note metadata.',
          deprecated: { reason: DEPRECATION_REASON, milestone: '15.7' }
        field :can_delete, GraphQL::Types::Boolean,
          null: true,
          description: 'Whether current user can delete description version associated to the note metadata.',
          deprecated: { reason: DEPRECATION_REASON, milestone: '15.7' }
        field :deleted, GraphQL::Types::Boolean,
          null: true,
          method: :deleted?,
          description: 'Whether description version associated to the note metadata is deleted.',
          deprecated: { reason: DEPRECATION_REASON, milestone: '15.7' }

        def diff_path
          return unless object.issuable.present? && description_diff_available?

          description_diff_path(object.issuable, object.id)
        end

        def delete_path
          return unless object.issuable.present? && description_diff_available?

          delete_description_version_path(object.issuable, object.id)
        end

        def can_delete
          return unless object.issuable.present? && description_diff_available?

          rule = "admin_#{object.issuable.class.to_ability_name}"
          Ability.allowed?(current_user, rule, object.issuable.resource_parent)
        end
      end

      private

      def description_diff_available?
        object.resource_parent.licensed_feature_available?(:description_diffs)
      end
    end
  end
end
