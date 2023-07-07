# frozen_string_literal: true

module Elastic
  module Latest
    module EpicConfig
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env, 'epics'].join('-')

      settings Elastic::Latest::Config.settings.to_hash.deep_merge(
        index: Elastic::Latest::Config.separate_index_specific_settings(index_name)
      )

      mappings dynamic: 'strict' do
        indexes :id, type: :integer
        indexes :iid, type: :integer
        indexes :group_id, type: :integer

        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        indexes :title, type: :text, index_options: 'positions'
        indexes :description, type: :text, index_options: 'positions'
        indexes :state, type: :keyword
        indexes :confidential, type: :boolean
        indexes :author_id, type: :integer
        indexes :label_ids, type: :keyword
        indexes :start_date, type: :date
        indexes :due_date, type: :date

        indexes :traversal_ids, type: :keyword
        indexes :hashed_root_namespace_id, type: :integer
        indexes :visibility_level, type: :integer

        indexes :schema_version, type: :short
        indexes :type, type: :keyword
      end
    end
  end
end
