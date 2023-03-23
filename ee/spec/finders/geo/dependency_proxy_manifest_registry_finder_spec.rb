# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DependencyProxyManifestRegistryFinder, feature_category: :geo_replication do
  it_behaves_like 'a framework registry finder', :geo_dependency_proxy_manifest_registry
end
