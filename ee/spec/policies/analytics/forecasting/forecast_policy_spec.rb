# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Forecasting::ForecastPolicy, feature_category: :devops_reports do
  subject(:policy) { described_class.new(current_user, forecast) }

  let(:forecast) { Analytics::Forecasting::Forecast.for(type).new(type: type, context: project) }
  let_it_be(:project) { create(:project) }

  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }
  let_it_be(:guest) { create(:user).tap { |u| project.add_guest(u) } }
  let(:current_user) { reporter }

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  describe 'deployment_frequency' do
    let(:type) { 'deployment_frequency' }

    context 'when project has no license to dora4' do
      before do
        stub_licensed_features(dora4_analytics: false)
      end

      it { is_expected.to be_disallowed(:build_forecast) }
    end

    context 'when user is not Reporter+' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:build_forecast) }
    end

    context 'when project has license to dora4 and user is Reporter+' do
      it { is_expected.to be_allowed(:build_forecast) }
    end
  end
end
