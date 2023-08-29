# frozen_string_literal: true

module Elastic
  module Latest
    class SnippetInstanceProxy < ApplicationInstanceProxy
      SCHEMA_VERSION = 23_08

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributes
        # https://gitlab.com/gitlab-org/gitlab/issues/349
        data = {}

        [
          :id,
          :title,
          :description,
          :created_at,
          :updated_at,
          :project_id,
          :author_id,
          :visibility_level
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data['schema_version'] = SCHEMA_VERSION

        data.merge(generic_attributes)
      end

      # TODO: Reenable support for public/internal project snippets
      # https://gitlab.com/gitlab-org/gitlab/issues/2358
      def es_parent
        nil
      end
    end
  end
end
