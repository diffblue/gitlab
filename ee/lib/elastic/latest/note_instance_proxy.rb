# frozen_string_literal: true

module Elastic
  module Latest
    class NoteInstanceProxy < ApplicationInstanceProxy
      delegate :noteable, to: :target

      def as_indexed_json(options = {})
        # `noteable` can be sometimes be nil (eg. when a commit has been
        # deleted) or somehow it was left orphaned in the database. In such
        # cases we want to delete it from the index since there is no value in
        # having orphaned notes be searchable.
        raise Elastic::Latest::DocumentShouldBeDeletedFromIndexError.new(target.class.name, target.id) if noteable.nil?

        data = {}

        # We don't use as_json(only: ...) because it calls all virtual and serialized attributes
        # https://gitlab.com/gitlab-org/gitlab/issues/349
        [:id, :note, :project_id, :noteable_type, :noteable_id, :created_at, :updated_at, :confidential].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        # We're migrating the `confidential` Note column to `internal` and therefore write to both attributes.
        # https://gitlab.com/groups/gitlab-org/-/epics/9634
        data['internal'] = safely_read_attribute_for_elasticsearch(:internal)

        data['hashed_root_namespace_id'] = target&.project&.namespace&.hashed_root_namespace_id

        if noteable.is_a?(Issue)
          data['issue'] = {
            'assignee_id' => noteable.assignee_ids,
            'author_id' => noteable.author_id,
            'confidential' => noteable.confidential
          }
        end

        data['visibility_level'] = target.project&.visibility_level || Gitlab::VisibilityLevel::PRIVATE
        merge_project_feature_access_level(data)

        data.merge(generic_attributes)
      end

      def generic_attributes
        super.except('join_field')
      end

      private

      def merge_project_feature_access_level(data)
        case noteable
        when Snippet
          data['snippets_access_level'] = safely_read_project_feature_for_elasticsearch(:snippets)
        when Commit
          data['repository_access_level'] = safely_read_project_feature_for_elasticsearch(:repository)
        when Issue, MergeRequest
          access_level_attribute = ProjectFeature.access_level_attribute(noteable)
          data[access_level_attribute.to_s] = safely_read_project_feature_for_elasticsearch(noteable)
        else
          # do nothing for other note types (DesignManagement::Design, AlertManagement::Alert, Epic, Vulnerability )
          # are indexed but not currently searchable so we will not add permission
          # data for them until the search capability is implemented
        end
      end
    end
  end
end
