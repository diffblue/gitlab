# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::RegistryBatcher,
  :use_clean_rails_memory_store_caching,
  feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:source_class) { LfsObject }
  let(:destination_class) { Geo::LfsObjectRegistry }
  let(:destination_class_factory) { registry_factory_name(destination_class) }

  include_examples 'is a Geo batcher'
end
