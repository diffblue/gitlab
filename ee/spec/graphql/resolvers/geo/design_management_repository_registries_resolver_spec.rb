# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::DesignManagementRepositoryRegistriesResolver, feature_category: :geo_replication do
  it_behaves_like 'a Geo registries resolver', :geo_design_management_repository_registry
end
