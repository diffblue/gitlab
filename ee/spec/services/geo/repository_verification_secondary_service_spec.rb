# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerificationSecondaryService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:repository_state) { create(:repository_state, project: project, repository_verification_checksum: '62fc1ec4ce60', wiki_verification_checksum: '62fc1ec4ce60') }

    let(:registry) { create(:geo_project_registry, :synced, project: project) }
    let(:repository) { project.repository }

    subject(:service)  { described_class.new(registry, :repository) }

    it 'does not calculate the checksum when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(false)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if resync is needed' do
      registry.assign_attributes(resync_repository: true)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if primary was never verified' do
      repository_state.assign_attributes(repository_verification_checksum: nil)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if the current checksum matches' do
      repository_state.assign_attributes(repository_verification_checksum: '62fc1ec4ce60')
      registry.assign_attributes(repository_verification_checksum_sha: '62fc1ec4ce60')

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'sets checksum when the checksum matches' do
      allow(repository).to receive(:checksum).and_return('62fc1ec4ce60')

      service.execute

      expect(registry).to have_attributes(
        repository_verification_checksum_sha: '62fc1ec4ce60',
        repository_checksum_mismatch: false,
        last_repository_verification_ran_at: be_within(1.minute).of(Time.current),
        last_repository_verification_failure: nil,
        repository_verification_retry_count: nil,
        resync_repository: false,
        repository_retry_at: nil,
        repository_retry_count: nil
      )
    end

    it 'does not mark the verification as failed when there is no repo' do
      allow(repository).to receive(:checksum).and_raise(Gitlab::Git::Repository::NoRepository)

      repository_state.assign_attributes(repository_verification_checksum: '0000000000000000000000000000000000000000')

      service.execute

      expect(registry).to have_attributes(
        repository_verification_checksum_sha: '0000000000000000000000000000000000000000',
        repository_checksum_mismatch: false,
        last_repository_verification_ran_at: be_within(1.minute).of(Time.current),
        last_repository_verification_failure: nil,
        repository_verification_retry_count: nil,
        resync_repository: false,
        repository_retry_at: nil,
        repository_retry_count: nil
      )
    end

    it 'does not calculate the wiki checksum' do
      service = described_class.new(registry, :wiki)

      expect(project.wiki.repository).not_to receive(:checksum)

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

    context 'when the checksum mismatch' do
      before do
        allow(repository).to receive(:checksum).and_return('99fc1ec4ce60')
      end

      it 'keeps track of failures' do
        service.execute

        expect(registry).to have_attributes(
          repository_verification_checksum_sha: nil,
          repository_verification_checksum_mismatched: '99fc1ec4ce60',
          repository_checksum_mismatch: true,
          last_repository_verification_ran_at: be_within(1.minute).of(Time.current),
          last_repository_verification_failure: "#{:repository.to_s.capitalize} checksum mismatch",
          repository_verification_retry_count: 1,
          resync_repository: true,
          repository_retry_at: be_present,
          repository_retry_count: 1
        )
      end

      it 'ensures the next retry time is capped properly' do
        registry.update!(repository_retry_count: 30)

        service.execute

        expect(registry).to have_attributes(
          resync_repository: true,
          repository_retry_at: be_within(100.seconds).of(1.hour.from_now),
          repository_retry_count: 31
        )
      end
    end

    context 'when checksum calculation fails' do
      before do
        allow(repository).to receive(:checksum).and_raise("Something went wrong with repository")
      end

      it 'keeps track of failures' do
        service.execute

        expect(registry).to have_attributes(
          repository_verification_checksum_sha: nil,
          repository_verification_checksum_mismatched: nil,
          repository_checksum_mismatch: false,
          last_repository_verification_ran_at: be_within(1.minute).of(Time.current),
          last_repository_verification_failure: "Error calculating repository checksum",
          repository_verification_retry_count: 1,
          resync_repository: true,
          repository_retry_at: be_present,
          repository_retry_count: 1
        )
      end

      it 'ensures the next retry time is capped properly' do
        registry.update!(repository_retry_count: 30)

        service.execute

        expect(registry).to have_attributes(
          resync_repository: true,
          repository_retry_at: be_within(100.seconds).of(1.hour.from_now),
          repository_retry_count: 31
        )
      end
    end
  end
end
