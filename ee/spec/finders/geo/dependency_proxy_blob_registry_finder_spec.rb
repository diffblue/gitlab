# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DependencyProxyBlobRegistryFinder, feature_category: :geo_replication do
  it_behaves_like 'a framework registry finder', :geo_dependency_proxy_blob_registry
end
