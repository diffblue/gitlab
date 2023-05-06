# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::EditionMetric, feature_category: :service_ping do
  context 'for EE edition' do
    before do
      allow(Gitlab).to receive(:ee?).and_return(true)
    end

    context 'with no license' do
      let(:expected_value) { 'EE Free' }

      before do
        allow(::License).to receive(:current).and_return(nil)
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' }
    end

    context 'with license' do
      let(:expected_value) { 'EE Premium' }

      before do
        license = instance_double(::License, edition: expected_value)
        allow(::License).to receive(:current).and_return(license)
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' }
    end
  end
end
