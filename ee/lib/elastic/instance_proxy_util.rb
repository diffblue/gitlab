# frozen_string_literal: true

# Stores stable methods for ApplicationInstanceProxy
# which is unlikely to change from version to version.
module Elastic
  module InstanceProxyUtil
    extend ActiveSupport::Concern

    def initialize(target, use_separate_indices: false)
      super(target)

      const_name = if use_separate_indices
                     if target.class.superclass.abstract_class?
                       "#{target.class.name}Config"
                     else
                       "#{target.class.superclass.name}Config"
                     end
                   else
                     'Config'
                   end

      config = version_namespace.const_get(const_name, false)

      @index_name = load_index_name(config)
      @document_type = config.document_type
    end

    ### Multi-version utils

    def real_class
      self.singleton_class.superclass
    end

    def version_namespace
      real_class.module_parent
    end

    class_methods do
      def methods_for_all_write_targets
        [:index_document, :delete_document, :update_document, :update_document_attributes]
      end

      def methods_for_one_write_target
        []
      end
    end

    private

    def load_index_name(config)
      index_partitioning_enabled? ? search_write_index_path : config.index_name
    end

    def index_partitioning_enabled?
      case target
      when Note
        Feature.enabled?(:search_index_partitioning_notes, target.project)
      else
        false
      end
    end

    def search_write_index_path
      search_index = target.search_index

      unless search_index.present?
        raise ArgumentError, "Search index assignment was missing for #{target.class} with id: `#{target.id}`"
      end

      search_index.path
    end

    # Some attributes are actually complicated methods. Bad data can cause
    # them to raise exceptions. When this happens, we still want the remainder
    # of the object to be saved, so silently swallow the errors
    def safely_read_attribute_for_elasticsearch(attr_name)
      result = target.send(attr_name) # rubocop:disable GitlabSecurity/PublicSend
      apply_field_limit(result)
    rescue StandardError => err
      target.logger.warn("Elasticsearch failed to read #{attr_name} for #{target.class} #{target.id}: #{err}")
      nil
    end

    # protect against missing project and project_feature and set visibility to PRIVATE
    # if the project_feature is missing on a project
    def safely_read_project_feature_for_elasticsearch(feature)
      return ProjectFeature::DISABLED unless target.project

      if target.project.project_feature
        target.project.project_feature.access_level(feature)
      else
        logger.warn(
          message: 'Project is missing ProjectFeature',
          project_id: target.project_id,
          id: target.id,
          class: target.class
        )
        ProjectFeature::PRIVATE
      end
    end

    def apply_field_limit(result)
      return result unless result.is_a? String

      limit = Gitlab::CurrentSettings.elasticsearch_indexed_field_length_limit

      return result unless limit > 0

      result[0, limit]
    end
  end
end
