# frozen_string_literal: true

module API
  module Entities
    module Search
      module Zoekt # rubocop:disable Search/NamespacedClass
        class IndexedNamespace < Grape::Entity # rubocop:disable Search/NamespacedClass
          expose :id, documentation: { type: :int, example: 1234 }
          expose :zoekt_shard_id, documentation: { type: :int, example: 1234 }
          expose :namespace_id, documentation: { type: :int, example: 1234 }
        end

        class Shard < Grape::Entity # rubocop:disable Search/NamespacedClass
          expose :id, documentation: { type: :int, example: 1234 }
          expose :index_base_url, documentation: { type: :string, example: 'http://127.0.0.1:6060/' }
          expose :search_base_url, documentation: { type: :string, example: 'http://127.0.0.1:6070/' }
        end

        class ProjectIndexSuccess < Grape::Entity # rubocop:disable Search/NamespacedClass
          expose :job_id do |item|
            item[:job_id]
          end
        end
      end
    end
  end
end
