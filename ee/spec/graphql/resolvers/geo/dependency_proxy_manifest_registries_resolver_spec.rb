# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::DependencyProxyManifestRegistriesResolver, feature_category: :geo_replication do
  it_behaves_like 'a Geo registries resolver', :geo_dependency_proxy_manifest_registry
end
