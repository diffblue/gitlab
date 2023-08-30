# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectWikiRepositoryRegistry, :geo, type: :model, feature_category: :geo_replication do
  let_it_be(:registry) { build(:geo_project_wiki_repository_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'
end
