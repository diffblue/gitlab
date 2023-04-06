# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::GeoNodeStatusCheck, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:current_node) { create(:geo_node) }

  let(:geo_node_status) do
    build(:geo_node_status, :replicated_and_verified, geo_node: current_node)
  end

  let(:subject) { described_class.new(geo_node_status, current_node) }

  describe '#replication_verification_complete?' do
    before do
      # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
      # is not allowed within a transaction but all RSpec tests run inside of a transaction.
      stub_batch_counter_transaction_open_check
      allow(Gitlab.config.geo.registry_replication).to receive(:enabled).and_return(true)
    end

    context 'with legacy replication' do
      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        it 'prints messages for all legacy replication and verification checks' do
          checks = [
            /Repositories: /,
            /Verified Repositories: /,
            /Wikis: /,
            /Verified Wikis: /,
            /Uploads: /,
            /Container repositories: /,
            /Design repositories: /
          ]

          checks.each do |text|
            expect { subject.print_replication_verification_status }.to output(text).to_stdout
          end
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        it 'prints messages for all legacy replication and verification checks' do
          checks = [
            /Repositories: /,
            /Verified Repositories: /,
            /Uploads: /,
            /Container repositories: /,
            /Design repositories: /
          ]

          checks.each do |text|
            expect { subject.print_replication_verification_status }.to output(text).to_stdout
          end
        end
      end
    end

    context 'replicators' do
      context 'replication' do
        let(:replicators) { Gitlab::Geo.enabled_replicator_classes }
        let(:checks) do
          replicators.map { |k| /#{k.replicable_title_plural}:/ }
        end

        it 'prints messages for replication' do
          checks.each do |text|
            expect { subject.print_replication_verification_status }.to output(text).to_stdout
          end
        end
      end

      context 'verification' do
        let(:replicators) { Gitlab::Geo.verification_enabled_replicator_classes }
        let(:checks) do
          replicators.map { |k| /#{k.replicable_title_plural} Verified:/ }
        end

        context 'when verification is enabled' do
          it 'prints messages for verification checks' do
            checks.each do |text|
              expect { subject.print_replication_verification_status }.to output(text).to_stdout
            end
          end
        end

        context 'when verification is disabled' do
          it 'does not print messages for verification checks' do
            replicators.each do |replicator|
              allow(replicator).to receive(:verification_enabled?).and_return(false)
            end

            checks.each do |text|
              expect { subject.print_replication_verification_status }.not_to output(text).to_stdout
            end
          end
        end
      end
    end

    context 'when replication is up-to-date' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:repository_checks_enabled).and_return(true)
      end

      it 'returns true when all replicables have data to sync' do
        expect(subject.replication_verification_complete?).to be_truthy
      end

      it 'returns true when some replicables does not have data to sync' do
        geo_node_status.update!(
          container_repositories_count: 0,
          lfs_objects_count: 0,
          package_files_count: 0,
          repositories_count: 0,
          wikis_count: 0
        )

        expect(subject.replication_verification_complete?).to be_truthy
      end
    end

    context 'when replication is not up-to-date' do
      it 'returns false when not all replicables were synced' do
        geo_node_status.update!(repositories_synced_count: 5)

        expect(subject.replication_verification_complete?).to be_falsy
      end
    end
  end
end
