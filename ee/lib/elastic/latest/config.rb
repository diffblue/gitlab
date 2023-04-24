# frozen_string_literal: true

module Elastic
  module Latest
    module Config
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.module_parent_name.downcase, Rails.env].join('-')

      settings \
        index: {
          number_of_shards: Elastic::AsJSON.new { Elastic::IndexSetting.default.number_of_shards },
          number_of_replicas: Elastic::AsJSON.new { Elastic::IndexSetting.default.number_of_replicas },
          highlight: {
            # `highlight.max_analyzed_offset` is technically not measured in
            # bytes, but rather in characters. Since this is an uppper bound on
            # the number of characters that can be highlighted before
            # Elasticsearch will error it is fine to use the number of bytes as
            # the upper limit since you cannot fit more characters than bytes
            # in a file.
            max_analyzed_offset: Elastic::AsJSON.new { Gitlab::CurrentSettings.elasticsearch_indexed_file_size_limit_kb.kilobytes }
          },
          codec: 'best_compression',
          analysis: {
            analyzer: {
              default: {
                tokenizer: 'standard',
                filter: %w(lowercase stemmer)
              },
              my_ngram_analyzer: {
                tokenizer: 'my_ngram_tokenizer',
                filter: ['lowercase']
              },
              path_analyzer: {
                type: 'custom',
                tokenizer: 'path_tokenizer',
                filter: %w(lowercase asciifolding)
              },
              code_analyzer: {
                type: 'custom',
                tokenizer: 'whitespace',
                filter: %w(word_delimiter_graph_filter flatten_graph lowercase asciifolding remove_duplicates)
              },
              whitespace_reverse: {
                tokenizer: 'whitespace',
                filter: %w(lowercase asciifolding reverse)
              },
              email_analyzer: {
                tokenizer: 'email_tokenizer'
              }
            },
            filter: {
              word_delimiter_graph_filter: {
                type: 'word_delimiter_graph',
                preserve_original: true
              }
            },
            tokenizer: {
              my_ngram_tokenizer: {
                type: 'ngram',
                min_gram: 2,
                max_gram: 3,
                token_chars: %w(letter digit)
              },
              path_tokenizer: {
                type: 'path_hierarchy',
                reverse: true
              },
              email_tokenizer: {
                type: 'uax_url_email'
              }
            },
            normalizer: {
              sha_normalizer: {
                type: "custom",
                filter: ["lowercase"]
              }
            }
          }
        }

      # Since we can't have multiple types in ES6, but want to be able to use JOINs, we must declare all our
      # fields together instead of per model
      mappings dynamic: 'strict' do
        ### Shared fields
        indexes :id, type: :integer
        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        # ES6-compatible way of having a parent, this is shared with all
        # Please note that if we add a parent to `project` we'll have to use that "grand-parent" as the routing value
        # for all children of project - therefore it is not advised.
        indexes :join_field,
          type: :join,
          relations: {
            project: %i(
              issue
              merge_request
              milestone
              note
              blob
              wiki_blob
              commit
            )
          }
        # ES6 requires a single type per index, so we implement our own "type"
        indexes :type, type: :keyword
        indexes :schema_version, type: :short

        indexes :iid, type: :integer

        indexes :title, type: :text, index_options: 'positions'
        indexes :description, type: :text, index_options: 'positions'
        indexes :state, type: :keyword
        indexes :project_id, type: :integer
        indexes :author_id, type: :integer
        # For using prefix queries for an efficient search on items
        indexes :traversal_ids, type: :keyword

        ## Projects and Snippets
        indexes :visibility_level, type: :integer

        ### ISSUES
        indexes :confidential, type: :boolean

        # The field assignee_id does not exist in issues table anymore.
        # Nevertheless we'll keep this field as is because we don't want users to rebuild index
        # + the ES treats arrays transparently so
        # to any integer field you can write any array of integers and you don't have to change mapping.
        # More over you can query those items just like a single integer value.
        indexes :assignee_id, type: :integer

        ### MERGE REQUESTS
        indexes :target_branch, type: :keyword
        indexes :source_branch, type: :keyword
        indexes :merge_status, type: :keyword
        indexes :source_project_id, type: :integer
        indexes :target_project_id, type: :integer

        ### NOTES
        indexes :note, type: :text, index_options: 'positions'

        indexes :issue do
          indexes :assignee_id, type: :integer
          indexes :author_id, type: :integer
          indexes :confidential, type: :boolean
        end

        # ES6 gets rid of "index: :not_analyzed" option, but a keyword type behaves the same
        # as it is not analyzed and is only searchable by its exact value.
        indexes :noteable_type, type: :keyword
        indexes :noteable_id, type: :keyword

        ### PROJECTS
        indexes :name, type: :text, index_options: 'positions'
        indexes :path, type: :text, index_options: 'positions'
        indexes :name_with_namespace, type: :text, index_options: 'positions', analyzer: :my_ngram_analyzer
        indexes :path_with_namespace, type: :text, index_options: 'positions'
        indexes :namespace_id, type: :integer
        indexes :archived, type: :boolean

        indexes :issues_access_level, type: :integer
        indexes :merge_requests_access_level, type: :integer
        indexes :snippets_access_level, type: :integer
        indexes :wiki_access_level, type: :integer
        indexes :repository_access_level, type: :integer

        indexes :last_activity_at, type: :date
        indexes :last_pushed_at, type: :date

        ### REPOSITORIES
        indexes :blob do
          indexes :type, type: :keyword

          indexes :id, type: :keyword, index_options: 'docs', normalizer: :sha_normalizer
          indexes :rid, type: :keyword
          indexes :oid, type: :keyword, index_options: 'docs', normalizer: :sha_normalizer
          indexes :commit_sha, type: :keyword, index_options: 'docs', normalizer: :sha_normalizer
          indexes :path, type: :text, analyzer: :path_analyzer
          indexes :file_name,
            type: :text, analyzer: :code_analyzer,
            fields: { reverse: { type: :text, analyzer: :whitespace_reverse } }
          indexes :content,
            type: :text, index_options: 'positions', analyzer: :code_analyzer
          indexes :language, type: :keyword
        end

        indexes :commit do
          indexes :type, type: :keyword

          indexes :id, type: :keyword, index_options: 'docs', normalizer: :sha_normalizer
          indexes :rid, type: :keyword
          indexes :sha, type: :keyword, index_options: 'docs', normalizer: :sha_normalizer

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

          indexes :message, type: :text, index_options: 'positions'
        end
      end
    end
  end
end
