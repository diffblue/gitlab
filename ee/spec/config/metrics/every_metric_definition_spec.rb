# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every metric definition', feature_category: :service_ping do
  let_it_be(:settings) { build(:application_setting, elasticsearch_search: true, elasticsearch_indexing: true) }

  before do
    allow(Gitlab::Geo).to receive(:enabled?).and_return(true)
    allow(::Gitlab::CurrentSettings).to receive(:current_application_settings).and_return(settings)
  end

  include_examples "every metric definition"
end
