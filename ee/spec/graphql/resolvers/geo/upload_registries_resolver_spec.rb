# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::UploadRegistriesResolver do
  it_behaves_like 'a Geo registries resolver', :geo_upload_registry
end
