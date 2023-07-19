# frozen_string_literal: true

class AddArchivedToWikis < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    ::Elastic::Latest::WikiConfig.index_name
  end

  def new_mappings
    { archived: { type: 'boolean' } }
  end
end
