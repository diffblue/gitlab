# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo, :geo, :request_store do
  using RSpec::Parameterized::TableSyntax
  include ::EE::GeoHelpers

  let_it_be(:primary_node)   { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  shared_examples 'a Geo cached value' do |method, key|
    it 'includes GitLab version and Rails.version in the cache key' do
      expanded_key = "geo:#{key}:#{Gitlab::VERSION}:#{Rails.version}"

      expect(Gitlab::ProcessMemoryCache.cache_backend).to receive(:write)
        .with(expanded_key, an_instance_of(String), expires_in: 1.minute).and_call_original
      expect(Rails.cache).to receive(:write)
        .with(expanded_key, an_instance_of(String), expires_in: 2.minutes)

      described_class.public_send(method)
    end
  end

  describe '.current_node' do
    it 'returns a GeoNode instance' do
      expect(GeoNode).to receive(:current_node).and_return(primary_node)

      expect(described_class.current_node).to eq(primary_node)
    end

    it_behaves_like 'a Geo cached value', :current_node, :current_node
  end

  describe '.primary_node' do
    it 'returns a GeoNode primary instance' do
      expect(described_class.primary_node).to eq(primary_node)
    end

    it_behaves_like 'a Geo cached value', :primary_node, :primary_node
  end

  describe '.secondary_nodes' do
    it 'returns a list of Geo secondary nodes' do
      expect(described_class.secondary_nodes).to match_array(secondary_node)
    end

    it_behaves_like 'a Geo cached value', :secondary_nodes, :secondary_nodes
  end

  describe '.primary?' do
    context 'when current node is a primary node' do
      before do
        stub_current_geo_node(primary_node)
      end

      it 'returns true' do
        expect(described_class.primary?).to be_truthy
      end

      it 'returns false when GeoNode is disabled' do
        allow(described_class).to receive(:enabled?) { false }

        expect(described_class.primary?).to be_falsey
      end
    end
  end

  describe '.primary_node_configured?' do
    context 'when current node is a primary node' do
      it 'returns true' do
        expect(described_class.primary_node_configured?).to be_truthy
      end

      it 'returns false when primary does not exist' do
        primary_node.destroy!

        expect(described_class.primary_node_configured?).to be_falsey
      end
    end
  end

  describe '.current_node_misconfigured?' do
    it 'returns true when current node is not set' do
      expect(described_class.current_node_misconfigured?).to be_truthy
    end

    it 'returns false when primary' do
      stub_current_geo_node(primary_node)

      expect(described_class.current_node_misconfigured?).to be_falsey
    end

    it 'returns false when secondary' do
      stub_current_geo_node(secondary_node)

      expect(described_class.current_node_misconfigured?).to be_falsey
    end

    it 'returns false when Geo is disabled' do
      GeoNode.delete_all

      expect(described_class.current_node_misconfigured?).to be_falsey
    end
  end

  describe '.secondary?' do
    context 'when current node is a secondary node' do
      before do
        stub_current_geo_node(secondary_node)
      end

      it 'returns true' do
        expect(described_class.secondary?).to be_truthy
      end

      it 'returns false when GeoNode is disabled' do
        allow(described_class).to receive(:enabled?) { false }

        expect(described_class.secondary?).to be_falsey
      end
    end

    context 'when current node is a primary node' do
      it 'returns false' do
        expect(described_class.secondary?).to be_falsey
      end
    end
  end

  describe '.secondary_with_primary?' do
    context 'when current node is a primary node' do
      it 'returns false' do
        expect(described_class.secondary_with_primary?).to be_falsey
      end
    end

    context 'when current node is a secondary node' do
      before do
        stub_current_geo_node(secondary_node)
      end

      it 'returns true' do
        expect(described_class.secondary_with_primary?).to be_truthy
      end

      context 'when a primary does not exist' do
        it 'returns false' do
          allow(::Gitlab::Geo).to receive(:primary_node_configured?).and_return(false)

          expect(described_class.secondary_with_primary?).to be_falsey
        end
      end
    end
  end

  describe '.secondary_with_unified_url?' do
    context 'when current node is a primary node' do
      it 'returns false' do
        expect(described_class.secondary_with_unified_url?).to be_falsey
      end
    end

    context 'when current node is a secondary node' do
      before do
        stub_current_geo_node(secondary_node)
      end

      context 'when a primary does not exist' do
        it 'returns false' do
          allow(::Gitlab::Geo).to receive(:primary_node_configured?).and_return(false)

          expect(described_class.secondary_with_unified_url?).to be_falsey
        end
      end

      context 'when the secondary node has different URLs' do
        it 'returns false' do
          expect(described_class.secondary_with_unified_url?).to be_falsey
        end
      end

      context 'when the secondary node has unified URL' do
        before do
          stub_current_geo_node(create(:geo_node, url: primary_node.url))
        end

        it 'returns true' do
          expect(described_class.secondary_with_unified_url?).to be_truthy
        end
      end
    end
  end

  describe '.proxied_request?' do
    it 'returns true when the header is set' do
      expect(described_class.proxied_request?({ 'HTTP_GITLAB_WORKHORSE_GEO_PROXY' => '1' })).to be_truthy
    end

    it 'returns false when the header is not present or set o an invalid value' do
      expect(described_class.proxied_request?({})).to be_falsey
      expect(described_class.proxied_request?({ 'HTTP_GITLAB_WORKHORSE_GEO_PROXY' => 'invalid' })).to be_falsey
    end
  end

  describe '.enabled?' do
    it_behaves_like 'a Geo cached value', :enabled?, :node_enabled

    context 'when any GeoNode exists' do
      it 'returns true' do
        expect(described_class.enabled?).to be_truthy
      end
    end

    context 'when no GeoNode exists' do
      before do
        GeoNode.delete_all
      end

      it 'returns false' do
        expect(described_class.enabled?).to be_falsey
      end
    end
  end

  describe '.oauth_authentication' do
    context 'for Geo secondary' do
      before do
        stub_secondary_node
        stub_current_geo_node(secondary_node)
      end

      it_behaves_like 'a Geo cached value', :oauth_authentication, :oauth_application
    end

    context 'for Geo primary' do
      before do
        stub_current_geo_node(primary_node)
      end

      it 'returns nil' do
        expect(described_class.oauth_authentication).to be_nil
      end
    end
  end

  describe '.connected?' do
    context 'when there is a database issue' do
      it 'returns false when it cannot open an active database connection' do
        allow(GeoNode.retrieve_connection).to receive(:active?).and_return(false)

        expect(described_class.connected?).to be_falsey
      end

      it 'returns false when the table does not exist' do
        allow(GeoNode).to receive(:table_exists?) { false }

        expect(described_class.connected?).to be_falsey
      end
    end
  end

  describe '.expire_cache!' do
    it 'clears the Geo cache keys', :request_store do
      described_class::CACHE_KEYS.each do |key|
        content = "#{key}-content"

        described_class.cache_value(key) { content }
        expect(described_class.cache_value(key)).to eq(content)
      end

      described_class.expire_cache!

      described_class::CACHE_KEYS.each do |key|
        expect(described_class.cache_value(key) { nil }).to be_nil
      end
    end
  end

  describe '.expire_cache_keys!' do
    it 'clears specified keys', :request_store do
      cache_data = { one: 1, two: 2 }

      cache_data.each do |key, value|
        described_class.cache_value(key) { value }
        expect(described_class.cache_value(key)).to eq(value)
      end

      described_class.expire_cache_keys!(cache_data.keys)

      cache_data.keys.each do |key|
        expect(described_class.cache_value(key) { nil }).to be_nil
      end
    end
  end

  describe '.license_allows?' do
    it 'returns true if license has Geo addon' do
      stub_licensed_features(geo: true)
      expect(described_class.license_allows?).to be_truthy
    end

    it 'returns false if license doesnt have Geo addon' do
      stub_licensed_features(geo: false)
      expect(described_class.license_allows?).to be_falsey
    end

    it 'returns false if no license is present' do
      allow(License).to receive(:current) { nil }
      expect(described_class.license_allows?).to be_falsey
    end
  end

  describe '.generate_access_keys' do
    it 'returns a public and secret access key' do
      keys = described_class.generate_access_keys

      expect(keys[:access_key].length).to eq(20)
      expect(keys[:secret_access_key].length).to eq(40)
    end
  end

  describe '.configure_cron_jobs!' do
    let(:manager) { double('cron_manager').as_null_object }

    before do
      allow(Gitlab::Geo::CronManager).to receive(:new) { manager }
    end

    it 'creates a cron watcher' do
      expect(manager).to receive(:create_watcher!)

      described_class.configure_cron_jobs!
    end

    it 'runs the cron manager' do
      expect(manager).to receive(:execute)

      described_class.configure_cron_jobs!
    end
  end

  describe '.repository_verification_enabled?' do
    context "when the feature flag hasn't been set" do
      it 'returns true' do
        expect(described_class.repository_verification_enabled?).to eq true
      end
    end

    context 'when the feature flag has been set' do
      context 'when the feature flag is set to enabled' do
        it 'returns true' do
          stub_feature_flags(geo_repository_verification: true)

          expect(described_class.repository_verification_enabled?).to eq true
        end
      end

      context 'when the feature flag is set to disabled' do
        it 'returns false' do
          stub_feature_flags(geo_repository_verification: false)

          expect(described_class.repository_verification_enabled?).to eq false
        end
      end
    end
  end

  describe '.allowed_ip?' do
    where(:allowed_ips, :ip, :allowed) do
      "192.1.1.1"                  | "192.1.1.1"     | true
      "192.1.1.1, 192.1.2.1"       | "192.1.2.1"     | true
      "192.1.1.0/24"               | "192.1.1.223"   | true
      "192.1.0.0/16"               | "192.1.223.223" | true
      "192.1.0.0/16, 192.1.2.0/24" | "192.1.2.223"   | true
      "192.1.0.0/16"               | "192.2.1.1"     | false
      "192.1.0.1"                  | "192.2.1.1"     | false
    end

    with_them do
      specify do
        stub_application_setting(geo_node_allowed_ips: allowed_ips)

        expect(described_class.allowed_ip?(ip)).to eq(allowed)
      end
    end
  end

  describe '.proxying_to_primary_message' do
    it 'returns a message as a string' do
      url = 'ssh://git@primary.com/namespace/repo.git'
      message = <<~STR
      This request to a Geo secondary node will be forwarded to the
      Geo primary node:

        #{url}
      STR

      expect(described_class.interacting_with_primary_message(url)).to eq(message)
    end
  end

  describe '.redirecting_to_primary_message' do
    it 'returns a message as a string' do
      url = 'http://primary.com/namespace/repo.git'
      message = <<~STR
      This request to a Geo secondary node will be forwarded to the
      Geo primary node:

        #{url}
      STR

      expect(described_class.interacting_with_primary_message(url)).to eq(message)
    end
  end

  describe '.enabled_replicator_classes' do
    it 'returns an Array of replicator classes' do
      result = described_class.enabled_replicator_classes

      expect(result).to be_an(Array)
      expect(result).to include(Geo::PackageFileReplicator)
    end

    context 'when replication is disabled' do
      before do
        stub_feature_flags(geo_package_file_replication: false)
      end

      it 'does not return the replicator class' do
        expect(described_class.enabled_replicator_classes).not_to include(Geo::PackageFileReplicator)
      end
    end
  end

  describe '.verification_enabled_replicator_classes' do
    it 'returns an Array of replicator classes' do
      result = described_class.verification_enabled_replicator_classes

      expect(result).to be_an(Array)
      expect(result).to include(Geo::PackageFileReplicator)
    end

    context 'when replication is disabled' do
      before do
        stub_feature_flags(geo_package_file_replication: false)
      end

      it 'does not return the replicator class' do
        expect(described_class.verification_enabled_replicator_classes).not_to include(Geo::PackageFileReplicator)
      end
    end
  end

  describe '.verification_max_capacity_per_replicator_class' do
    let(:verification_max_capacity) { 12 }
    let(:node) { double('node', verification_max_capacity: verification_max_capacity) }

    before do
      stub_current_geo_node(node)
    end

    context 'when there are no Replicator classes with verification enabled' do
      it 'returns the total capacity' do
        allow(described_class).to receive(:verification_enabled_replicator_classes).and_return([])

        expect(described_class.verification_max_capacity_per_replicator_class).to eq(verification_max_capacity)
      end
    end

    context 'when there is 1 Replicator class with verification enabled' do
      it 'returns half capacity' do
        allow(described_class).to receive(:verification_enabled_replicator_classes).and_return(['a replicator class'])

        expect(described_class.verification_max_capacity_per_replicator_class).to eq(verification_max_capacity / 2)
      end
    end

    context 'when there are 2 Replicator classes with verification enabled' do
      it 'returns a third of total capacity' do
        allow(described_class).to receive(:verification_enabled_replicator_classes).and_return(['a replicator class', 'another replicator class'])

        expect(described_class.verification_max_capacity_per_replicator_class).to eq(verification_max_capacity / 3)
      end
    end

    context 'when total capacity is set lower than the number of Replicators' do
      let(:verification_max_capacity) { 1 }

      it 'returns 1' do
        expect(described_class.verification_max_capacity_per_replicator_class).to eq(1)
      end
    end
  end

  describe '.uncached_queries' do
    context 'when no block is given' do
      it 'raises error' do
        expect do
          described_class.uncached_queries
        end.to raise_error('No block given')
      end
    end

    context 'when the current node is a primary' do
      it 'wraps the block in an ApplicationRecord.uncached block' do
        stub_current_geo_node(primary_node)

        expect(Geo::TrackingBase).not_to receive(:uncached)
        expect(ApplicationRecord).to receive(:uncached).and_call_original

        expect do |b|
          described_class.uncached_queries(&b)
        end.to yield_control
      end
    end

    context 'when the current node is a secondary' do
      it 'wraps the block in a Geo::TrackingBase.uncached block and an ApplicationRecord.uncached block' do
        stub_current_geo_node(secondary_node)

        expect(Geo::TrackingBase).to receive(:uncached).and_call_original
        expect(ApplicationRecord).to receive(:uncached).and_call_original

        expect do |b|
          described_class.uncached_queries(&b)
        end.to yield_control
      end
    end

    context 'when there is no current node' do
      it 'wraps the block in an ApplicationRecord.uncached block' do
        expect(Geo::TrackingBase).not_to receive(:uncached)
        expect(ApplicationRecord).to receive(:uncached).and_call_original

        expect do |b|
          described_class.uncached_queries(&b)
        end.to yield_control
      end
    end
  end
end
