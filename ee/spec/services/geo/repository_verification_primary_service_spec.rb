# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerificationPrimaryService do
  include EE::GeoHelpers

  let(:project) { create(:project) }
  let(:project_wiki_repository) { create(:project_wiki_repository, project: project) }
  let(:repository) { double(checksum: 'f123') }
  let(:wiki) { double(checksum: 'e321') }

  subject(:service) { described_class.new(project) }

  describe '#perform', :aggregate_failures do
    it 'calculates the checksum for unverified projects' do
      stub_project_repository(project, repository)
      stub_wiki_repository(project.wiki, wiki)

      subject.execute

      expect(project.repository_state).to have_attributes(
        repository_verification_checksum: 'f123',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: 'e321',
        last_wiki_verification_ran_at: be_present,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )

      expect(project.wiki_repository_state).to have_attributes(
        project_wiki_repository: be_present,
        verification_state: Projects::WikiRepository.verification_state_value(:verification_succeeded),
        verification_checksum: 'e321',
        verification_started_at: be_present,
        verification_failure: nil,
        verification_retry_at: nil,
        verification_retry_count: 0,
        verified_at: be_present
      )
    end

    it 'calculates the checksum for outdated repositories/wikis' do
      stub_project_repository(project, repository)
      stub_wiki_repository(project.wiki, wiki)

      project_repository_state =
        create(:project_repository_state,
          :repository_outdated,
          :wiki_outdated,
          project: project
        )

      wiki_repository_state =
        create(:geo_project_wiki_repository_state,
          project: project,
          project_wiki_repository: project_wiki_repository,
          verification_state: Projects::WikiRepository.verification_state_value(:verification_pending),
          verification_checksum: nil,
          verification_started_at: 1.day.ago,
          verified_at: 1.day.ago,
          verification_failure: nil)

      subject.execute

      expect(project_repository_state.reload).to have_attributes(
        repository_verification_checksum: 'f123',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: 'e321',
        last_wiki_verification_ran_at: be_present,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )

      expect(wiki_repository_state.reload).to have_attributes(
        project_wiki_repository: be_present,
        verification_state: Projects::WikiRepository.verification_state_value(:verification_succeeded),
        verification_checksum: 'e321',
        verification_started_at: be_present,
        verification_failure: nil,
        verification_retry_at: nil,
        verification_retry_count: 0,
        verified_at: be_present
      )
    end

    it 'recalculates the checksum for projects up to date' do
      stub_project_repository(project, repository)
      stub_wiki_repository(project.wiki, wiki)

      create(:project_repository_state,
        project: project,
        repository_verification_checksum: 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee',
        last_repository_verification_ran_at: 1.day.ago,
        wiki_verification_checksum: 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef',
        last_wiki_verification_ran_at: 1.day.ago)

      create(:geo_project_wiki_repository_state,
        project: project,
        project_wiki_repository: project_wiki_repository,
        verification_state: Projects::WikiRepository.verification_state_value(:verification_succeeded),
        verification_checksum: 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee',
        verification_started_at: 1.day.ago,
        verified_at: 1.day.ago)

      expect(repository).to receive(:checksum).once
      expect(wiki).to receive(:checksum).once

      subject.execute

      expect(project.repository_state).to have_attributes(
        last_repository_verification_ran_at: be_within(100.seconds).of(Time.current),
        last_wiki_verification_ran_at: be_within(100.seconds).of(Time.current)
      )

      expect(project.wiki_repository_state.reload).to have_attributes(
        verification_started_at: be_within(100.seconds).of(Time.current),
        verified_at: be_within(100.seconds).of(Time.current)
      )
    end

    it 'calculates the wiki checksum even when wiki is not enabled for project' do
      stub_project_repository(project, repository)
      stub_wiki_repository(project.wiki, wiki)

      project.update!(wiki_enabled: false)

      subject.execute

      expect(project.repository_state).to have_attributes(
        repository_verification_checksum: 'f123',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: 'e321',
        last_wiki_verification_ran_at: be_present,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )

      expect(project.wiki_repository_state).to have_attributes(
        project_wiki_repository: be_present,
        verification_state: Projects::WikiRepository.verification_state_value(:verification_succeeded),
        verification_checksum: 'e321',
        verification_started_at: be_present,
        verification_failure: nil,
        verification_retry_at: nil,
        verification_retry_count: 0,
        verified_at: be_present
      )
    end

    it 'does not mark the calculating as failed when there is no repo' do
      subject.execute

      expect(project.repository_state).to have_attributes(
        repository_verification_checksum: '0000000000000000000000000000000000000000',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: '0000000000000000000000000000000000000000',
        last_wiki_verification_ran_at: be_present,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )

      expect(project.wiki_repository_state).to have_attributes(
        project_wiki_repository: be_present,
        verification_state: Projects::WikiRepository.verification_state_value(:verification_succeeded),
        verification_checksum: '0000000000000000000000000000000000000000',
        verification_started_at: be_present,
        verification_failure: nil,
        verification_retry_at: nil,
        verification_retry_count: 0,
        verified_at: be_present
      )
    end

    it 'does not mark the calculating as failed for non-valid repo' do
      stub_project_repository(project, repository)
      stub_wiki_repository(project.wiki, wiki)

      expect(repository).to receive(:checksum).and_raise(Gitlab::Git::Repository::InvalidRepository)
      expect(wiki).to receive(:checksum).and_raise(Gitlab::Git::Repository::InvalidRepository)

      subject.execute

      expect(project.repository_state).to have_attributes(
        repository_verification_checksum: '0000000000000000000000000000000000000000',
        last_repository_verification_ran_at: be_present,
        last_repository_verification_failure: nil,
        wiki_verification_checksum: '0000000000000000000000000000000000000000',
        last_wiki_verification_ran_at: be_present,
        last_wiki_verification_failure: nil,
        repository_retry_at: nil,
        repository_retry_count: nil,
        wiki_retry_at: nil,
        wiki_retry_count: nil
      )

      expect(project.wiki_repository_state).to have_attributes(
        project_wiki_repository: be_present,
        verification_state: Projects::WikiRepository.verification_state_value(:verification_succeeded),
        verification_checksum: '0000000000000000000000000000000000000000',
        verification_started_at: be_present,
        verification_failure: nil,
        verification_retry_at: nil,
        verification_retry_count: 0,
        verified_at: be_present
      )
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

    context 'when checksum calculation fails' do
      before do
        stub_project_repository(project, repository)
        stub_wiki_repository(project.wiki, wiki)

        allow(repository).to receive(:checksum).and_raise('Something went wrong with repository')
        allow(wiki).to receive(:checksum).twice.and_raise('Something went wrong with wiki')
      end

      it 'keeps track of failures' do
        subject.execute

        expect(project.repository_state).to have_attributes(
          repository_verification_checksum: nil,
          last_repository_verification_ran_at: be_present,
          last_repository_verification_failure: 'Something went wrong with repository',
          wiki_verification_checksum: nil,
          last_wiki_verification_ran_at: be_present,
          last_wiki_verification_failure: 'Something went wrong with wiki',
          repository_retry_at: be_present,
          repository_retry_count: 1,
          wiki_retry_at: be_present,
          wiki_retry_count: 1
        )

        expect(project.wiki_repository_state).to have_attributes(
          project_wiki_repository: be_present,
          verification_state: Projects::WikiRepository.verification_state_value(:verification_failed),
          verification_checksum: nil,
          verification_started_at: be_present,
          verification_failure: 'Something went wrong with wiki',
          verification_retry_at: be_present,
          verification_retry_count: 1,
          verified_at: be_present
        )
      end

      it 'ensures the next retry time is capped properly' do
        project_repository_state =
          create(:project_repository_state,
            project: project,
            repository_retry_count: 30,
            wiki_retry_count: 30)

        wiki_repository_state =
          create(:geo_project_wiki_repository_state,
            project: project,
            project_wiki_repository: project_wiki_repository,
            verification_retry_count: 30)

        subject.execute

        expect(project_repository_state.reload).to have_attributes(
          repository_verification_checksum: nil,
          last_repository_verification_ran_at: be_present,
          last_repository_verification_failure: 'Something went wrong with repository',
          wiki_verification_checksum: nil,
          last_wiki_verification_ran_at: be_present,
          last_wiki_verification_failure: 'Something went wrong with wiki',
          repository_retry_at: be_within(100.seconds).of(1.hour.from_now),
          repository_retry_count: 31,
          wiki_retry_at: be_within(100.seconds).of(1.hour.from_now),
          wiki_retry_count: 31
        )

        expect(wiki_repository_state.reload).to have_attributes(
          project_wiki_repository: be_present,
          verification_state: Projects::WikiRepository.verification_state_value(:verification_failed),
          verification_checksum: nil,
          verification_started_at: be_present,
          verification_failure: 'Something went wrong with wiki',
          verification_retry_at: be_within(100.seconds).of(1.hour.from_now),
          verification_retry_count: 31,
          verified_at: be_present
        )
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

  def stub_wiki_repository(wiki, repository)
    allow(Repository).to receive(:new).with(
      project.wiki.full_path,
      project.wiki,
      shard: project.repository_storage,
      disk_path: project.wiki.disk_path,
      repo_type: Gitlab::GlRepository::WIKI
    ).and_return(repository)
  end
end
