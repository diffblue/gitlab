# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Admin::Geo::NodesController, :geo, feature_category: :geo_replication do
  shared_examples 'unlicensed geo action' do
    it 'redirects to the 403 page' do
      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#index' do
    render_views

    shared_examples 'no flash message' do |flash_type|
      it 'does not display a flash message' do
        go

        expect(flash).not_to include(flash_type)
      end
    end

    shared_examples 'with flash message' do |flash_type, message|
      it 'displays a flash message' do
        go

        expect(flash[flash_type]).to match(message)
      end
    end

    def go
      get :index
    end

    context 'with valid license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
        go
      end

      it 'does not show license alert' do
        expect(response).to render_template(partial: '_license_alert')
        expect(response.body).not_to include(
          'Geo is only available for users who have at least a Premium subscription.'
        )
      end
    end

    context 'without valid license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
        go
      end

      it 'does show license alert' do
        expect(response).to render_template(partial: '_license_alert')
        expect(response.body).to include('Geo is only available for users who have at least a Premium subscription.')
      end

      it 'does not redirects to the 403 page' do
        expect(response).not_to redirect_to(:forbidden)
      end
    end
  end

  describe '#create' do
    let(:geo_node_attributes) { { url: 'http://example.com' } }

    def go
      post :create, params: { geo_node: geo_node_attributes }
    end

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
        go
      end

      it_behaves_like 'unlicensed geo action'
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'delegates the create of the Geo node to Geo::NodeCreateService' do
        expect_next_instance_of(Geo::NodeCreateService) do |instance|
          expect(instance).to receive(:execute).once.and_call_original
        end

        go
      end
    end
  end

  describe '#update' do
    let(:geo_node_attributes) do
      {
        url: 'http://example.com',
        internal_url: 'http://internal-url.com',
        selective_sync_shards: %w[foo bar]
      }
    end

    let(:geo_node) { create(:geo_node) }

    def go
      post :update, params: { id: geo_node, geo_node: geo_node_attributes }
    end

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
        go
      end

      it_behaves_like 'unlicensed geo action'
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'updates the node' do
        go

        geo_node.reload
        expect(geo_node.url.chomp('/')).to eq(geo_node_attributes[:url])
        expect(geo_node.internal_url.chomp('/')).to eq(geo_node_attributes[:internal_url])
        expect(geo_node.selective_sync_shards).to eq(%w[foo bar])
      end

      it 'delegates the update of the Geo node to Geo::NodeUpdateService' do
        expect_next_instance_of(Geo::NodeUpdateService) do |instance|
          expect(instance).to receive(:execute).once
        end

        go
      end
    end
  end
end
