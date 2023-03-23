# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::CiSecureFileRegistriesResolver, feature_category: :geo_replication do
  it_behaves_like 'a Geo registries resolver', :geo_ci_secure_file_registry
end
