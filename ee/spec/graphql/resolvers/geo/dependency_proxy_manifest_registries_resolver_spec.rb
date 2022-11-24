# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::DependencyProxyManifestRegistriesResolver do
  it_behaves_like 'a Geo registries resolver', :geo_dependency_proxy_manifest_registry
end
