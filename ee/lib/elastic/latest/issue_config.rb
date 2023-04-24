# frozen_string_literal: true

module Elastic
  module Latest
    module IssueConfig
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env, 'issues'].join('-')

      settings Elastic::Latest::Config.settings.to_hash.deep_merge(
        index: {
          number_of_shards: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_shards },
          number_of_replicas: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_replicas }
        }
      )

      mappings dynamic: 'strict' do
        indexes :type, type: :keyword

        indexes :id, type: :integer
        indexes :iid, type: :integer

        indexes :title, type: :text, index_options: 'positions'
        indexes :description, type: :text, index_options: 'positions'
        indexes :created_at, type: :date
        indexes :updated_at, type: :date
        indexes :state, type: :keyword
        indexes :project_id, type: :integer
        indexes :author_id, type: :integer
        indexes :confidential, type: :boolean
        indexes :hidden, type: :boolean
        indexes :assignee_id, type: :integer

        indexes :visibility_level, type: :integer
        indexes :issues_access_level, type: :integer
        indexes :upvotes, type: :integer
        indexes :namespace_ancestry_ids, type: :keyword
        indexes :label_ids, type: :keyword
        indexes :hashed_root_namespace_id, type: :integer

        indexes :schema_version, type: :short
      end
    end
  end
end
