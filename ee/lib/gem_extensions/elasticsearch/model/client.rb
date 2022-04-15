# frozen_string_literal: true

# Override `__elasticsearch__.client` to
# return a client configured from application settings. All including
# classes will use the same instance, which is refreshed automatically
# if the settings change.
#
# _client is present to match the arity of the overridden method, where
# it is also not used.
module GemExtensions
  module Elasticsearch
    module Model
      module Client
        CLIENT_MUTEX = Mutex.new

        cattr_accessor :cached_client
        cattr_accessor :cached_config
        cattr_accessor :cached_adapter

        def client(_client = nil)
          store = ::GemExtensions::Elasticsearch::Model::Client

          store::CLIENT_MUTEX.synchronize do
            config = ::Gitlab::CurrentSettings.elasticsearch_config
            adapter = ::Gitlab::Elastic::Client.adapter

            if store.cached_client.nil? || config != store.cached_config || adapter != store.cached_adapter
              store.cached_client = ::Gitlab::Elastic::Client.build(config.deep_dup)
              store.cached_config = config
              store.cached_adapter = adapter
            end
          end

          store.cached_client
        end
      end
    end
  end
end
