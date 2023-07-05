# frozen_string_literal: true

module Elastic
  module Latest
    module ProjectConfig
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env,
        'projects'].join('-')

      settings Elastic::Latest::Config.settings.to_hash.deep_merge(
        index: Elastic::Latest::Config.separate_index_specific_settings(index_name)
      )

      mappings dynamic: 'strict' do
        indexes :id, type: :integer
        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        indexes :type, type: :keyword
        indexes :name, type: :text, index_options: 'positions'
        indexes :path, type: :text, index_options: 'positions'

        indexes :name_with_namespace, type: :text, index_options: 'positions', analyzer: :my_ngram_analyzer
        indexes :description, type: :text, index_options: 'positions'
        indexes :path_with_namespace, type: :text, index_options: 'positions'
        indexes :namespace_id, type: :integer

        indexes :archived, type: :boolean
        indexes :traversal_ids, type: :keyword
        indexes :visibility_level, type: :integer

        indexes :last_activity_at, type: :date
        indexes :schema_version, type: :short

        indexes :ci_catalog, type: :boolean
        indexes :readme_content, type: :text
      end
    end
  end
end
