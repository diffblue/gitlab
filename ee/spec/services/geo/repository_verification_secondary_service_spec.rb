# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerificationSecondaryService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  shared_examples 'verify checksums for repositories/wikis' do |type|
    let(:repository) { find_repository(type) }

    subject(:service)  { described_class.new(registry, type) }

    it 'does not calculate the checksum when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(false)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if resync is needed' do
      registry.assign_attributes("resync_#{type}" => true)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if primary was never verified' do
      repository_state.assign_attributes("#{type}_verification_checksum" => nil)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if the current checksum matches' do
      repository_state.assign_attributes("#{type}_verification_checksum" => '62fc1ec4ce60')
      registry.assign_attributes("#{type}_verification_checksum_sha" => '62fc1ec4ce60')

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'sets checksum when the checksum matches' do
      allow(repository).to receive(:checksum).and_return('62fc1ec4ce60')

      service.execute

      expect(registry).to have_attributes(
        "#{type}_verification_checksum_sha" => '62fc1ec4ce60',
        "#{type}_checksum_mismatch" => false,
        "last_#{type}_verification_ran_at" => be_within(1.minute).of(Time.current),
        "last_#{type}_verification_failure" => nil,
        "#{type}_verification_retry_count" => nil,
        "resync_#{type}" => false,
        "#{type}_retry_at" => nil,
        "#{type}_retry_count" => nil
      )
    end

    it 'does not mark the verification as failed when there is no repo' do
      allow(repository).to receive(:checksum).and_raise(Gitlab::Git::Repository::NoRepository)

      repository_state.assign_attributes("#{type}_verification_checksum" => '0000000000000000000000000000000000000000')

      service.execute

      expect(registry).to have_attributes(
        "#{type}_verification_checksum_sha" => '0000000000000000000000000000000000000000',
        "#{type}_checksum_mismatch" => false,
        "last_#{type}_verification_ran_at" => be_within(1.minute).of(Time.current),
        "last_#{type}_verification_failure" => nil,
        "#{type}_verification_retry_count" => nil,
        "resync_#{type}" => false,
        "#{type}_retry_at" => nil,
        "#{type}_retry_count" => nil
      )
    end

    context 'when the checksum mismatch' do
      before do
        allow(repository).to receive(:checksum).and_return('99fc1ec4ce60')
      end

      it 'keeps track of failures' do
        service.execute

        expect(registry).to have_attributes(
          "#{type}_verification_checksum_sha" => nil,
          "#{type}_verification_checksum_mismatched" => '99fc1ec4ce60',
          "#{type}_checksum_mismatch" => true,
          "last_#{type}_verification_ran_at" => be_within(1.minute).of(Time.current),
          "last_#{type}_verification_failure" => "#{type.to_s.capitalize} checksum mismatch",
          "#{type}_verification_retry_count" => 1,
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_present,
          "#{type}_retry_count" => 1
        )
      end

      it 'ensures the next retry time is capped properly' do
        registry.update!("#{type}_retry_count" => 30)

        service.execute

        expect(registry).to have_attributes(
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_within(100.seconds).of(1.hour.from_now),
          "#{type}_retry_count" => 31
        )
      end
    end

    context 'when checksum calculation fails' do
      before do
        allow(repository).to receive(:checksum).and_raise("Something went wrong with #{type}")
      end

      it 'keeps track of failures' do
        service.execute

        expect(registry).to have_attributes(
          "#{type}_verification_checksum_sha" => nil,
          "#{type}_verification_checksum_mismatched" => nil,
          "#{type}_checksum_mismatch" => false,
          "last_#{type}_verification_ran_at" => be_within(1.minute).of(Time.current),
          "last_#{type}_verification_failure" => "Error calculating #{type} checksum",
          "#{type}_verification_retry_count" => 1,
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_present,
          "#{type}_retry_count" => 1
        )
      end

      it 'ensures the next retry time is capped properly' do
        registry.update!("#{type}_retry_count" => 30)

        service.execute

        expect(registry).to have_attributes(
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_within(100.seconds).of(1.hour.from_now),
          "#{type}_retry_count" => 31
        )
      end
    end

    def find_repository(type)
      case type
      when :repository then project.repository
      when :wiki then project.wiki.repository
      end
    end
  end

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:repository_state) { create(:repository_state, project: project, repository_verification_checksum: '62fc1ec4ce60', wiki_verification_checksum: '62fc1ec4ce60') }

    let(:registry) { create(:geo_project_registry, :synced, project: project) }

    context 'for a repository' do
      include_examples 'verify checksums for repositories/wikis', :repository
    end

    context 'for a wiki' do
      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        include_examples 'verify checksums for repositories/wikis', :wiki
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        let(:repository) { project.wiki.repository }

        subject(:service)  { described_class.new(registry, :wiki) }

        before do
          stub_feature_flags(geo_project_wiki_repository_replication: true)
        end

        it 'does not calculate the wiki checksum' do
          expect(repository).not_to receive(:checksum)

          service.execute

          expect(registry).to have_attributes(
            wiki_verification_checksum_sha: nil,
            wiki_checksum_mismatch: false,
            last_wiki_verification_ran_at: nil,
            last_wiki_verification_failure: nil,
            wiki_verification_retry_count: nil,
            resync_wiki: false,
            wiki_retry_at: nil,
            wiki_retry_count: nil
          )
        end
      end
    end
  end
end
