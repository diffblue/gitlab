# frozen_string_literal: true

class AddCiCatalogToProject < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Project.__elasticsearch__.index_name
  end

  def new_mappings
    {
      readme_content: {
        type: 'text'
      },
      ci_catalog: {
        type: 'boolean'
      }
    }
  end
end
