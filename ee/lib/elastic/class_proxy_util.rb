# frozen_string_literal: true

# Stores stable methods for ApplicationClassProxy
# which is unlikely to change from version to version.
module Elastic
  module ClassProxyUtil
    extend ActiveSupport::Concern

    attr_reader :use_separate_indices

    def initialize(target, use_separate_indices: false)
      super(target)

      # use_separate_indices check is needed to load custom mappings for AR and non-AR classes
      # For example, Issue and Commit
      const_name = use_separate_indices ? "#{target.base_class}Config" : 'Config'

      config = version_namespace.const_get(const_name, false)

      @index_name = config.index_name
      @document_type = config.document_type
      @settings = config.settings
      @mapping = config.mapping
      @use_separate_indices = use_separate_indices
    end

    ### Multi-version utils

    alias_method :real_class, :class

    def version_namespace
      self.class.module_parent
    end

    class_methods do
      def methods_for_all_write_targets
        %i[refresh_index!]
      end

      def methods_for_one_write_target
        %i[import create_index! delete_index!]
      end
    end
  end
end
