# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerificationPrimaryService, feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:project) { create(:project) }
  let(:repository) { double(checksum: 'f123') }

  subject(:service) { described_class.new(project) }

  describe '#perform' do
    it 'calculates the checksum for unverified projects' do
      stub_project_repository(project, repository)

      subject.execute

      expect(project.repository_state).to have_attributes(
        repository_verification_checksum: 'f123',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: nil,
        last_wiki_verification_ran_at: nil,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )
    end

    it 'calculates the checksum for outdated repositories' do
      stub_project_repository(project, repository)

      repository_state =
        create(:repository_state,
          :repository_outdated,
          project: project
        )

      subject.execute

      expect(repository_state.reload).to have_attributes(
        repository_verification_checksum: 'f123',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: nil,
        last_wiki_verification_ran_at: nil,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )
    end

    it 'recalculates the checksum for projects up to date' do
      stub_project_repository(project, repository)

      create(:repository_state,
        project: project,
        repository_verification_checksum: 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee',
        last_repository_verification_ran_at: 1.day.ago)

      expect(repository).to receive(:checksum)

      subject.execute

      expect(project.repository_state).to have_attributes(
        last_repository_verification_ran_at: be_within(100.seconds).of(Time.current),
        last_wiki_verification_ran_at: nil
      )
    end

    it 'does not mark the calculating as failed when there is no repo' do
      subject.execute

      expect(project.repository_state).to have_attributes(
        repository_verification_checksum: '0000000000000000000000000000000000000000',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: nil,
        last_wiki_verification_ran_at: nil,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )
    end

    it 'does not mark the calculating as failed for non-valid repo' do
      stub_project_repository(project, repository)

      expect(repository).to receive(:checksum).and_raise(Gitlab::Git::Repository::InvalidRepository)

      service.execute

      expect(project.repository_state).to have_attributes(
        repository_verification_checksum: '0000000000000000000000000000000000000000',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: nil,
        last_wiki_verification_ran_at: nil,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )
    end

    context 'when checksum calculation fails' do
      before do
        stub_project_repository(project, repository)

        allow(repository).to receive(:checksum).and_raise('Something went wrong with repository')
      end

      it 'keeps track of failures' do
        subject.execute

        expect(project.repository_state).to have_attributes(
          repository_verification_checksum: nil,
          last_repository_verification_ran_at: be_present,
          last_repository_verification_failure: 'Something went wrong with repository',
          wiki_verification_checksum: nil,
          last_wiki_verification_ran_at: nil,
          last_wiki_verification_failure: nil,
          repository_retry_at: be_present,
          repository_retry_count: 1,
          wiki_retry_at: nil,
          wiki_retry_count: nil
        )
      end

      it 'ensures the next retry time is capped properly' do
        repository_state =
          create(:repository_state,
            project: project,
            repository_retry_count: 30)

        subject.execute

        expect(repository_state.reload).to have_attributes(
          repository_verification_checksum: nil,
          last_repository_verification_ran_at: be_present,
          last_repository_verification_failure: 'Something went wrong with repository',
          wiki_verification_checksum: nil,
          last_wiki_verification_ran_at: nil,
          last_wiki_verification_failure: nil,
          repository_retry_at: be_within(100.seconds).of(1.hour.from_now),
          repository_retry_count: 31,
          wiki_retry_at: nil,
          wiki_retry_count: nil
        )
      end
    end

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::ResetChecksumEvent event if there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { subject.execute }.not_to change(Geo::ResetChecksumEvent, :count)
      end

      it 'creates a Geo::ResetChecksumEvent event' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [build(:geo_node)] }

        expect { subject.execute }.to change(Geo::ResetChecksumEvent, :count).by(1)
      end
    end
  end

  def stub_project_repository(project, repository)
    allow(Repository).to receive(:new).with(
      project.full_path,
      project,
      shard: project.repository_storage,
      disk_path: project.disk_path
    ).and_return(repository)
  end
end
