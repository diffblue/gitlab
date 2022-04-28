# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::Metrics::UpdateService do
  let(:metric) { create(:prometheus_metric) }

  it 'updates the prometheus metric' do
    expect do
      described_class.new(metric, { title: "bar" }).execute
    end.to change { metric.reload.title }.to("bar")
  end
end
