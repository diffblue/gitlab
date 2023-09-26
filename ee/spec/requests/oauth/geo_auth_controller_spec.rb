# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::GeoAuthController, type: :request, feature_category: :geo_replication do
  it_behaves_like 'Base action controller' do
    subject(:request) { get metrics_path }
  end
end
