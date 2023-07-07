# frozen_string_literal: true

module Elastic
  module Latest
    class EpicInstanceProxy < ApplicationInstanceProxy
      def as_indexed_json(_options = {})
        data = {}

        [
          :id,
          :iid,
          :group_id,
          :created_at,
          :updated_at,
          :title,
          :description,
          :state,
          :confidential,
          :author_id
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data['label_ids'] = target.label_ids.map(&:to_s)
        data['start_date'] = target.start_date || target.start_date_from_inherited_source
        data['due_date'] = target.end_date || target.due_date_from_inherited_source

        data['traversal_ids'] = target.group.elastic_namespace_ancestry
        data['hashed_root_namespace_id'] = target.group.hashed_root_namespace_id
        data['visibility_level'] = target.group.visibility_level

        # Schema version. The format is Date.today.strftime('%y_%m')
        # Please update if you're changing the schema of the document
        data['schema_version'] = 23_06

        data.merge(generic_attributes)
      end

      def generic_attributes
        super.except('join_field')
      end

      def es_parent
        "group_#{group.root_ancestor.id}"
      end
    end
  end
end
