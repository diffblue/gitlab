# frozen_string_literal: true

module Elastic
  module Latest
    module MergeRequestConfig
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env, 'merge_requests'].join('-')

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
        indexes :state, type: :keyword
        indexes :project_id, type: :integer
        indexes :author_id, type: :integer

        indexes :target_branch, type: :keyword
        indexes :source_branch, type: :keyword
        indexes :merge_status, type: :keyword
        indexes :source_project_id, type: :integer
        indexes :target_project_id, type: :integer

        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        indexes :hidden, type: :boolean
        indexes :visibility_level, type: :integer
        indexes :merge_requests_access_level, type: :integer
        indexes :upvotes, type: :integer

        indexes :hashed_root_namespace_id, type: :integer
      end
    end
  end
end
