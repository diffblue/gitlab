# frozen_string_literal: true

class AddHiddenToIssues < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Issue.__elasticsearch__.index_name
  end

  def new_mappings
    {
      hidden: {
        type: 'boolean'
      }
    }
  end
end
