# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::CiSecureFileRegistryFinder do
  it_behaves_like 'a framework registry finder', :geo_ci_secure_file_registry
end
