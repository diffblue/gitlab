# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountSamlGroupLinksMetric do
  let_it_be(:saml_group_link) { create(:saml_group_link) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT("saml_group_links"."id") FROM "saml_group_links"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
