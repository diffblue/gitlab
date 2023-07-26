# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every metric definition', feature_category: :service_ping do
  before do
    allow(Gitlab::Geo).to receive(:enabled?).and_return(true)
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  include_examples "every metric definition"
end
