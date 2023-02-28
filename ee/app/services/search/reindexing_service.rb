# frozen_string_literal: true

module Search
  class ReindexingService
    def self.execute(*args, **kwargs)
      new(*args, **kwargs).execute
    end

    attr_reader :request

    def initialize(overrides: {}, **params)
      @request = build_request(params, overrides)
    end

    def execute
      client.reindex(**request)
    end

    private

    def build_request(params, overrides)
      r = {
        wait_for_completion: params[:wait_for_completion],
        body: {
          conflicts: params[:conflicts],
          max_docs: params[:max_docs],
          source: {
            index: params.fetch(:from),
            slice: {
              id: params[:slice_id],
              max: params[:max_slices]
            },
            query: params[:query]
          },
          dest: {
            index: params.fetch(:to)
          }
        }
      }

      recursively_compact(r).merge(overrides) do |_key, old_value, new_value|
        merge_hash_values(old_value, new_value)
      end
    end

    def recursively_compact(thing)
      return thing unless thing.respond_to? :keys

      hsh = thing.compact

      # Return nil for later compaction
      return if hsh.empty?

      hsh.each do |k, v|
        hsh[k] = recursively_compact(v)
      end

      # Compact a second time to remove empty hashes
      hsh.compact
    end

    def merge_hash_values(prev, new_values)
      # Merge values of nested hashes instead of overwriting them completely with new values
      if prev.respond_to?(:keys) && new_values.respond_to?(:keys)
        prev.merge(new_values)
      else
        new_values
      end
    end

    def client
      @client ||= ::Gitlab::Search::Client.new
    end
  end
end
