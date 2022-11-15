# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeoInstrumentation, feature_category: :geo_replication do
  let(:user) { create(:user) }

  controller(ActionController::Base) do
    include ::GeoInstrumentation

    def show
      render plain: "show action"
    end
  end

  before do
    routes.draw { get "show" => "anonymous#show" }
    sign_in(user) unless user.nil?
  end

  describe '.track_geo_proxy_event' do
    context 'when the request is not proxied' do
      before do
        allow(::Gitlab::Geo).to receive(:proxied_request?).and_return(false)
      end

      it 'does not track an event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)
        get :show
      end
    end

    context 'when the request is proxied' do
      before do
        allow(::Gitlab::Geo).to receive(:proxied_request?).and_return(true)
      end

      context 'when logged in' do
        it 'tracks a HLL event for unique geo proxied requests' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter)
            .to receive(:track_event).with('g_geo_proxied_requests', values: user.id)
          get :show
        end
      end

      context 'when not logged in' do
        let(:user) { nil }

        it 'does not track an event' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)
          get :show
        end
      end
    end
  end
end
