# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PackageFileRegistryFinder, feature_category: :geo_replication do
  it_behaves_like 'a framework registry finder', :geo_package_file_registry
end
