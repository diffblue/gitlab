# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::PackageFileRegistriesResolver, feature_category: :geo_replication do
  it_behaves_like 'a Geo registries resolver', :geo_package_file_registry
end
