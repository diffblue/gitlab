# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::UploadRegistryFinder do
  it_behaves_like 'a framework registry finder', :geo_upload_registry
end
