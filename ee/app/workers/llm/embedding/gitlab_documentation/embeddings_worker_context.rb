# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      module EmbeddingsWorkerContext
        extend ActiveSupport::Concern

        DOC_DIRECTORY = 'doc'
        BATCH_SIZE = 50

        class_methods do
          def get_embeddings_index
            ::Gitlab::Redis::SharedState.with do |redis|
              redis.get(embeddings_index_cache_key)
            end.to_i
          end

          def set_embeddings_index!(index)
            ::Gitlab::Redis::SharedState.with do |redis|
              redis.set(embeddings_index_cache_key, index.to_i, ex: 5.hours)
            end
          end

          def embeddings_index_cache_key
            'vertex_gitlab_documentation:embeddings:index'
          end
        end
      end
    end
  end
end
