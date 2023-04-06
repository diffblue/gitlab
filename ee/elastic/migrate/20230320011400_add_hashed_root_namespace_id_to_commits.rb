# frozen_string_literal: true

class AddHashedRootNamespaceIdToCommits < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    ::Elastic::Latest::CommitConfig.index_name
  end

  def new_mappings
    {
      hashed_root_namespace_id: {
        type: 'integer'
      }
    }
  end
end
