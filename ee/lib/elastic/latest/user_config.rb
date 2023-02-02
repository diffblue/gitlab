# frozen_string_literal: true

module Elastic
  module Latest
    module UserConfig
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env, 'users'].join('-')

      settings Elastic::Latest::Config.settings.to_hash.deep_merge(
        index: {
          number_of_shards: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_shards }, # rubocop:disable Style/RedundantSelf
          number_of_replicas: Elastic::AsJSON.new { Elastic::IndexSetting[self.index_name].number_of_replicas } # rubocop:disable Style/RedundantSelf
        }
      )

      mappings dynamic: 'strict' do
        indexes :type, type: :keyword
        indexes :id, type: :integer

        indexes :username, type: :text, fields: { raw: { type: :keyword } }
        indexes :email, type: :text, analyzer: :email_analyzer
        indexes :public_email, type: :text, analyzer: :email_analyzer
        indexes :name, type: :text

        indexes :state, type: :keyword
        indexes :admin, type: :boolean
        indexes :organization, type: :text
        indexes :timezone, type: :text
        indexes :status, type: :text
        indexes :status_emoji, type: :keyword
        indexes :busy, type: :boolean

        indexes :external, type: :boolean
        indexes :in_forbidden_state, type: :boolean

        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        indexes :namespace_ancestry_ids, type: :keyword
        indexes :schema_version, type: :short
      end
    end
  end
end
