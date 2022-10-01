# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryRegistryFinder do
  it_behaves_like 'a framework registry finder', :geo_container_repository_registry
end
