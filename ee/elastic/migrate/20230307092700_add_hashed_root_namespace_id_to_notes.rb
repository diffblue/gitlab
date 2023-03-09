# frozen_string_literal: true

class AddHashedRootNamespaceIdToNotes < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Note.__elasticsearch__.index_name
  end

  def new_mappings
    {
      hashed_root_namespace_id: {
        type: 'integer'
      }
    }
  end
end
