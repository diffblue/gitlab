# frozen_string_literal: true
module GemExtensions
  module Elasticsearch
    module Model
      module Indexing
        # We need `_id` to be the model's `#es_id` in all indexing/editing operations
        module InstanceMethods
          def index_document(options = {})
            document = self.as_indexed_json

            client.index(
              { index: index_name,
                id: self.es_id,
                body: document }.merge(options)
            )
          end

          def delete_document(options = {})
            client.delete(
              { index: index_name,
                id: self.es_id }.merge(options)
            )
          end

          # Code copied from gem, to disable checks
          # rubocop:disable Style/MultilineIfModifier
          def update_document(options = {})
            if attributes_in_database = self.instance_variable_get(:@__changed_model_attributes).presence
              attributes = if respond_to?(:as_indexed_json)
                             self.as_indexed_json.select { |k, _v| attributes_in_database.keys.map(&:to_s).include? k.to_s }
                           else
                             attributes_in_database
                           end

              client.update(
                { index: index_name,
                  id: self.es_id, # Changed
                  body: { doc: attributes } }.merge(options)
              ) unless attributes.empty?
            else
              index_document(options)
            end
          end
          # rubocop:enable Style/MultilineIfModifier

          def update_document_attributes(attributes, options = {})
            client.update(
              { index: index_name,
                id: self.es_id,
                body: { doc: attributes } }.merge(options)
            )
          end
        end
      end
    end
  end
end
