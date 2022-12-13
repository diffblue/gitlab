# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Features, stub_feature_flags: false, feature_category: :feature_flags do
  include EE::GeoHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    Feature.reset
    Flipper.unregister_groups
    Flipper.register(:perf_team) do |actor|
      actor.respond_to?(:admin) && actor.admin?
    end

    skip_feature_flags_yaml_validation
  end

  describe 'POST /feature' do
    let(:feature_name) do
      Feature::Definition.definitions
        .values.find(&:development?).name
    end

    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }
      end

      it 'creates Geo cache invalidation event' do
        expect do
          post api("/features/#{feature_name}", admin), params: { value: 'true' }
        end.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end

    context 'when licensed feature name is given' do
      let(:feature_name) do
        GitlabSubscriptions::Features::PLANS_BY_FEATURE.each_key.first
      end

      it 'returns bad request' do
        post api("/features/#{feature_name}", admin), params: { value: 'true' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'when force=1 is set' do
        it 'allows to change state' do
          post api("/features/#{feature_name}", admin), params: { value: 'true', force: true }

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end
  end

  describe 'DELETE /feature/:name' do
    let(:feature_name) { 'my_feature' }

    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }
      end

      it 'creates Geo cache invalidation event' do
        Feature.enable(feature_name)

        expect do
          delete api("/features/#{feature_name}", admin)
        end.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end
end
