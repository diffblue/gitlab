# frozen_string_literal: true

class AddNamespaceAncestryToIssuesMapping < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  DOCUMENT_KLASS = Issue

  private

  def index_name
    DOCUMENT_KLASS.__elasticsearch__.index_name
  end

  def new_mappings
    {
      namespace_ancestry: {
        type: 'text',
        index_prefixes: {
          min_chars: 1, max_chars: 19
        }
      }
    }
  end
end
