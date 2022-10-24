# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerificationSecondaryService, :geo do
  include ::EE::GeoHelpers

  shared_examples 'verify checksums for repositories/wikis' do |type|
    let(:repository) { find_repository(type) }

    subject(:service)  { described_class.new(project_repository_registry, type) }

    it 'does not calculate the checksum when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(false)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if resync is needed' do
      project_repository_registry.assign_attributes("resync_#{type}" => true)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if primary was never verified' do
      project_repository_state.assign_attributes("#{type}_verification_checksum" => nil)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if the current checksum matches' do
      project_repository_state.assign_attributes("#{type}_verification_checksum" => '62fc1ec4ce60')
      project_repository_registry.assign_attributes("#{type}_verification_checksum_sha" => '62fc1ec4ce60')

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'sets checksum when the checksum matches' do
      allow(repository).to receive(:checksum).and_return('62fc1ec4ce60')

      service.execute

      expect(project_repository_registry).to have_attributes(
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

      project_repository_state.assign_attributes("#{type}_verification_checksum" => '0000000000000000000000000000000000000000')

      service.execute

      expect(project_repository_registry).to have_attributes(
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

        expect(project_repository_registry).to have_attributes(
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
        project_repository_registry.update!("#{type}_retry_count" => 30)

        service.execute

        expect(project_repository_registry).to have_attributes(
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

        expect(project_repository_registry).to have_attributes(
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
        project_repository_registry.update!("#{type}_retry_count" => 30)

        service.execute

        expect(project_repository_registry).to have_attributes(
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

  describe '#execute', :aggregate_failures do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:project_repository_state) { create(:repository_state, project: project) }

    let(:project_repository_registry) { create(:geo_project_registry, :synced, project: project) }

    context 'for a repository' do
      include_examples 'verify checksums for repositories/wikis', :repository
    end

    context 'for a wiki with information in the project_repository_states table' do
      include_examples 'verify checksums for repositories/wikis', :wiki

      it 'does not create an entry in the project_wiki_repository_registry table' do
        allow(repository).to receive(:checksum).and_return('62fc1ec4ce60')

        subject = described_class.new(project_repository_registry, :wiki)

        expect { subject.execute }.not_to change(Geo::ProjectWikiRepositoryRegistry, :count)
      end
    end

    context 'for a wiki with information in the project_wiki_repository_states table' do
      context 'with an entry in the project_wiki_repository_state table' do
        let!(:wiki_repository_state) { create(:geo_project_wiki_repository_state, project: project) }
        let!(:wiki_repository_registry) { create(:geo_project_wiki_repository_registry, :synced, project: project) }
        let(:repository) { project.wiki.repository }

        subject(:service)  { described_class.new(project_repository_registry, :wiki) }

        it 'does not verify the checksum if primary was never verified' do
          wiki_repository_state.verification_checksum = nil
          project_repository_state.wiki_verification_checksum = nil

          expect(repository).not_to receive(:checksum)

          service.execute
        end

        it 'does not verify the checksum if the current checksum matches' do
          wiki_repository_state.verification_checksum = '62fc1ec4ce60'
          wiki_repository_registry.update!(verification_checksum: '62fc1ec4ce60')
          project_repository_state.wiki_verification_checksum = nil

          expect(repository).not_to receive(:checksum)

          service.execute
        end

        it 'sets checksum when the checksum matches' do
          wiki_repository_state.verification_checksum = '62fc1ec4ce60'
          project_repository_state.wiki_verification_checksum = nil

          allow(repository).to receive(:checksum).and_return('62fc1ec4ce60')

          service.execute

          expect(project_repository_registry).to have_attributes(
            wiki_verification_checksum_sha: '62fc1ec4ce60',
            wiki_checksum_mismatch: false,
            last_wiki_verification_ran_at: be_within(1.minute).of(Time.current),
            last_wiki_verification_failure: nil,
            wiki_verification_retry_count: nil,
            resync_wiki: false,
            wiki_retry_at: nil,
            wiki_retry_count: nil
          )

          expect(wiki_repository_registry.reload).to have_attributes(
            checksum_mismatch: false,
            verification_checksum: '62fc1ec4ce60',
            verification_checksum_mismatched: nil,
            verification_started_at: be_within(1.minute).of(Time.current),
            verified_at: be_within(1.minute).of(Time.current),
            verification_failure: nil,
            verification_state: Geo::ProjectWikiRepositoryRegistry.verification_state_value(:verification_succeeded),
            verification_retry_at: nil,
            verification_retry_count: 0
          )
        end

        it 'does not mark the verification as failed when there is no repo' do
          allow(repository).to receive(:checksum).and_raise(Gitlab::Git::Repository::NoRepository)

          wiki_repository_state.verification_checksum = '0000000000000000000000000000000000000000'

          service.execute

          expect(project_repository_registry).to have_attributes(
            wiki_verification_checksum_sha: '0000000000000000000000000000000000000000',
            wiki_checksum_mismatch: false,
            last_wiki_verification_ran_at: be_within(1.minute).of(Time.current),
            last_wiki_verification_failure: nil,
            wiki_verification_retry_count: nil,
            resync_wiki: false,
            wiki_retry_at: nil,
            wiki_retry_count: nil
          )

          expect(wiki_repository_registry.reload).to have_attributes(
            checksum_mismatch: false,
            verification_checksum: '0000000000000000000000000000000000000000',
            verification_checksum_mismatched: nil,
            verification_started_at: be_within(1.minute).of(Time.current),
            verified_at: be_within(1.minute).of(Time.current),
            verification_failure: nil,
            verification_state: Geo::ProjectWikiRepositoryRegistry.verification_state_value(:verification_succeeded),
            verification_retry_at: nil,
            verification_retry_count: 0
          )
        end

        context 'when the checksum mismatch' do
          before do
            wiki_repository_state.verification_checksum = '62fc1ec4ce60'
            project_repository_state.wiki_verification_checksum = nil

            allow(repository).to receive(:checksum).and_return('99fc1ec4ce60')
          end

          it 'keeps track of failures' do
            service.execute

            expect(project_repository_registry).to have_attributes(
              wiki_verification_checksum_sha: nil,
              wiki_verification_checksum_mismatched: '99fc1ec4ce60',
              wiki_checksum_mismatch: true,
              last_wiki_verification_ran_at: be_within(1.minute).of(Time.current),
              last_wiki_verification_failure: 'Wiki checksum mismatch',
              wiki_verification_retry_count: 1,
              resync_wiki: true,
              wiki_retry_at: be_present,
              wiki_retry_count: 1
            )

            expect(wiki_repository_registry.reload).to have_attributes(
              checksum_mismatch: true,
              verification_checksum: '99fc1ec4ce60',
              verification_checksum_mismatched: '99fc1ec4ce60',
              verification_started_at: be_within(1.minute).of(Time.current),
              verified_at: be_within(1.minute).of(Time.current),
              verification_failure: "Checksum does not match the primary checksum {:checksum=>\"99fc1ec4ce60\", :primary_checksum=>\"62fc1ec4ce60\"}",
              verification_state: Geo::ProjectWikiRepositoryRegistry.verification_state_value(:verification_failed),
              verification_retry_at: be_present,
              verification_retry_count: 1,
              last_sync_failure: "Verification failed with: Checksum does not match the primary checksum {:checksum=>\"99fc1ec4ce60\", :primary_checksum=>\"62fc1ec4ce60\"}"
            )
          end

          it 'ensures the next retry time is capped properly' do
            wiki_repository_registry.update!(retry_count: 30, verification_retry_count: 30)

            service.execute

            expect(project_repository_registry).to have_attributes(
              resync_wiki: true,
              wiki_retry_at: be_within(100.seconds).of(1.hour.from_now),
              wiki_verification_retry_count: 31,
              wiki_retry_count: 31
            )

            expect(wiki_repository_registry.reload).to have_attributes(
              verification_state: Geo::ProjectWikiRepositoryRegistry.verification_state_value(:verification_failed),
              verification_retry_at: be_within(100.seconds).of(1.hour.from_now),
              verification_retry_count: 31,
              retry_count: 31,
              last_sync_failure: "Verification failed with: Checksum does not match the primary checksum {:checksum=>\"99fc1ec4ce60\", :primary_checksum=>\"62fc1ec4ce60\"}"
            )
          end
        end

        context 'when checksum calculation fails' do
          before do
            allow(repository).to receive(:checksum).and_raise("Something went wrong with wiki")
          end

          it 'keeps track of failures' do
            wiki_repository_state.verification_checksum = '0000000000000000000000000000000000000000'

            service.execute

            expect(project_repository_registry).to have_attributes(
              wiki_verification_checksum_sha: nil,
              wiki_verification_checksum_mismatched: nil,
              wiki_checksum_mismatch: false,
              last_wiki_verification_ran_at: be_within(1.minute).of(Time.current),
              last_wiki_verification_failure: "Error calculating wiki checksum",
              wiki_verification_retry_count: 1,
              resync_wiki: true,
              wiki_retry_at: be_present,
              wiki_retry_count: 1
            )

            expect(wiki_repository_registry.reload).to have_attributes(
              checksum_mismatch: false,
              verification_checksum: nil,
              verification_checksum_mismatched: nil,
              verification_started_at: be_within(1.minute).of(Time.current),
              verified_at: be_within(1.minute).of(Time.current),
              verification_failure: "Error calculating wiki checksum: Something went wrong with wiki",
              verification_state: Geo::ProjectWikiRepositoryRegistry.verification_state_value(:verification_failed),
              verification_retry_at: be_present,
              verification_retry_count: 1
            )
          end

          it 'ensures the next retry time is capped properly' do
            wiki_repository_state.verification_checksum = '0000000000000000000000000000000000000000'
            wiki_repository_registry.update!(retry_count: 30, verification_retry_count: 30)

            service.execute

            expect(project_repository_registry).to have_attributes(
              resync_wiki: true,
              wiki_retry_at: be_within(100.seconds).of(1.hour.from_now),
              wiki_verification_retry_count: 31,
              wiki_retry_count: 31
            )

            expect(wiki_repository_registry.reload).to have_attributes(
              verification_state: Geo::ProjectWikiRepositoryRegistry.verification_state_value(:verification_failed),
              verification_retry_at: be_within(100.seconds).of(1.hour.from_now),
              verification_retry_count: 31,
              retry_count: 31,
              last_sync_failure: "Verification failed with: Error calculating wiki checksum: Something went wrong with wiki"
            )
          end
        end
      end
    end
  end
end
