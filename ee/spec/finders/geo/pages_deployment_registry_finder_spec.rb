# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PagesDeploymentRegistryFinder, feature_category: :geo_replication do
  it_behaves_like 'a framework registry finder', :geo_pages_deployment_registry
end
