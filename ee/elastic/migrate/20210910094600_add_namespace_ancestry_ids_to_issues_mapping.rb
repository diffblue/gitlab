# frozen_string_literal: true

class AddNamespaceAncestryIdsToIssuesMapping < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  DOCUMENT_TYPE = Issue

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def new_mappings
    {
      namespace_ancestry_ids: {
        type: 'keyword'
      }
    }
  end
end
