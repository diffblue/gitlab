# frozen_string_literal: true

module Elastic
  module Latest
    class ApplicationInstanceProxy < Elasticsearch::Model::Proxy::InstanceMethodsProxy
      include InstanceProxyUtil

      def es_parent
        "project_#{target.project_id}" unless target.is_a?(Project) || target&.project_id.nil?
      end

      def es_type
        self.class.es_type
      end

      def es_id
        "#{es_type}_#{target.id}"
      end

      def namespace_ancestry
        project = target.is_a?(Project) ? target : target.project
        namespace = project.namespace
        namespace.self_and_ancestor_ids(hierarchy_order: :desc).join('-')
      end

      private

      def generic_attributes
        attributes = { 'type' => es_type }

        if es_parent
          attributes['join_field'] = {
            'name' => es_type,
            'parent' => es_parent
          }
        end

        attributes
      end
    end
  end
end
