# frozen_string_literal: true

class ElasticDeleteProjectWorker
  include ApplicationWorker

  data_consistency :always
  prepend Elastic::IndexingControl

  sidekiq_options retry: 2
  feature_category :global_search
  urgency :throttled
  idempotent!

  def perform(project_id, es_id)
    remove_project_and_children_documents(project_id, es_id)
    IndexStatus.for_project(project_id).delete_all
  end

  private

  def indices
    helper = Gitlab::Elastic::Helper.default

    # some standalone indices may not be created yet if pending advanced search migrations exist
    standalone_indices = helper.standalone_indices_proxies.select do |klass|
      alias_name = helper.klass_to_alias_name(klass: klass)
      helper.index_exists?(index_name: alias_name)
    end

    [helper.target_name] + standalone_indices.map(&:index_name)
  end

  def remove_project_and_children_documents(project_id, es_id)
    Gitlab::Elastic::Helper.default.client.delete_by_query({
      index: indices,
      routing: es_id,
      body: {
        query: {
          bool: {
            should: [
              {
                term: {
                  _id: es_id
                }
              },
              {
                term: {
                  project_id: project_id
                }
              },
              {
                term: {
                  # We never set `project_id` for commits instead they have a nested rid which is the project_id
                  "commit.rid" => project_id
                }
              },
              {
                term: {
                  "rid" => project_id
                }
              },
              {
                term: {
                  target_project_id: project_id # handle merge_request which previously did not store project_id and only stored target_project_id
                }
              }
            ]
          }
        }
      }
    })
  end
end
