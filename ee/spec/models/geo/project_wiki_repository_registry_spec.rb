# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectWikiRepositoryRegistry, :geo, type: :model do
  let_it_be(:registry) { create(:geo_project_wiki_repository_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end
end
