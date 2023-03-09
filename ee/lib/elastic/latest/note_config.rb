# frozen_string_literal: true

module Elastic
  module Latest
    module NoteConfig
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env, 'notes'].join('-')

      settings Elastic::Latest::Config.settings.to_hash.deep_merge(
        index: {
          number_of_shards: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_shards },
          number_of_replicas: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_replicas }
        }
      )

      mappings dynamic: 'strict' do
        indexes :type, type: :keyword

        indexes :id, type: :integer

        indexes :note, type: :text, index_options: 'positions'
        indexes :project_id, type: :integer

        indexes :noteable_type, type: :keyword
        indexes :noteable_id, type: :keyword

        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        indexes :confidential, type: :boolean
        indexes :internal, type: :boolean

        indexes :visibility_level, type: :integer
        indexes :issues_access_level, type: :integer
        indexes :repository_access_level, type: :integer
        indexes :merge_requests_access_level, type: :integer
        indexes :snippets_access_level, type: :integer

        indexes :issue do
          indexes :assignee_id, type: :integer
          indexes :author_id, type: :integer
          indexes :confidential, type: :boolean
        end

        indexes :hashed_root_namespace_id, type: :integer
      end
    end
  end
end
