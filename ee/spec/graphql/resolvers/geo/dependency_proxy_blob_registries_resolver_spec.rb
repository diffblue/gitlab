# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::DependencyProxyBlobRegistriesResolver, feature_category: :geo_replication do
  it_behaves_like 'a Geo registries resolver', :geo_dependency_proxy_blob_registry
end
