# frozen_string_literal: true

class AddNamespaceAncestryToIssuesMapping < Elastic::Migration
  include Elastic::MigrationHelper

  DOCUMENT_KLASS = Issue

  def migrate
    if completed?
      log 'Skipping adding namespace_ancestry to issues mapping migration since it is already applied'
      return
    end

    log 'Adding namespace_ancestry to issues mapping'
    update_mapping!(index_name, { properties: { namespace_ancestry: { type: 'text', index_prefixes: { min_chars: 1, max_chars: 19 } } } })
  end

  def completed?
    helper.refresh_index(index_name: index_name)

    mappings = helper.get_mapping(index_name: index_name)
    mappings.dig('namespace_ancestry').present?
  end

  private

  def index_name
    DOCUMENT_KLASS.__elasticsearch__.index_name
  end
end
