# frozen_string_literal: true

module Elastic
  module Latest
    module CommitConfig
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env, 'commits'].join('-')

      settings Elastic::Latest::Config.settings.to_hash.deep_merge(
        index: {
          number_of_shards: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_shards },
          number_of_replicas: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_replicas }
        }
      )

      mappings dynamic: 'strict' do
        indexes :type, type: :keyword

        indexes :author do
          indexes :name, type: :text, index_options: 'positions'
          indexes :email, type: :keyword
          indexes :time, type: :date, format: :basic_date_time_no_millis
        end

        indexes :committer do
          indexes :name, type: :text, index_options: 'positions'
          indexes :email, type: :keyword
          indexes :time, type: :date, format: :basic_date_time_no_millis
        end

        indexes :id, type: :keyword,
                     index_options: 'docs',
                     normalizer: :sha_normalizer
        indexes :rid, type: :keyword
        indexes :sha, type: :keyword,
                      index_options: 'docs',
                      normalizer: :sha_normalizer
        indexes :message, type: :text, index_options: 'positions'
        indexes :visibility_level, type: :integer
        indexes :repository_access_level, type: :integer
        indexes :hashed_root_namespace_id, type: :integer
      end
    end
  end
end
