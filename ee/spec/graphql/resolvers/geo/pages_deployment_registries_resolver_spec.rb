# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::PagesDeploymentRegistriesResolver do
  it_behaves_like 'a Geo registries resolver', :geo_pages_deployment_registry
end
