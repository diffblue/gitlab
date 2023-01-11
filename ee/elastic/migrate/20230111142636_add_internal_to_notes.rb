# frozen_string_literal: true

class AddInternalToNotes < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Note.__elasticsearch__.index_name
  end

  def new_mappings
    {
      internal: {
        type: 'boolean'
      }
    }
  end
end
