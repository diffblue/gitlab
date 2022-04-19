# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OmniauthInitializer do
  include ::EE::GeoHelpers

  describe '.full_host' do
    subject { described_class.full_host.call({}) }

    let(:base_url) { 'http://localhost/test' }

    before do
      allow(Settings).to receive(:gitlab).and_return({ 'base_url' => base_url })
    end

    context 'with non-proxied request' do
      it { is_expected.to eq(base_url) }
    end

    context 'with a proxied request' do
      context 'for a non-existing node' do
        before do
          stub_proxied_site(nil)
        end

        it { is_expected.to eq(base_url) }
      end

      context 'for an existing node' do
        let(:geo_node) { instance_double(GeoNode, omniauth_host_url: 'http://localhost/geonode_url') }

        before do
          stub_proxied_site(geo_node)
        end

        it { is_expected.to eq(geo_node.omniauth_host_url) }
      end
    end
  end
end
