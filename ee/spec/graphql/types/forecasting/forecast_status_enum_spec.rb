# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ForecastStatus'], feature_category: :devops_reports do
  it 'exposes all statuses' do
    expect(described_class.values.keys).to include(*%w[READY UNAVAILABLE])
  end
end
