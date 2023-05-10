# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ForecastDatapoint'], feature_category: :devops_reports do
  it 'has expected fields' do
    expect(described_class).to have_graphql_fields(*%i[datapoint value])
  end
end
