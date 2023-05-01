# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRegistry, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  using RSpec::Parameterized::TableSyntax

  let(:registry) { create(:geo_project_registry) }

  subject { registry }

  it_behaves_like 'a BulkInsertSafe model', Geo::ProjectRegistry do
    let(:valid_items_for_bulk_insertion) do
      build_list(:geo_project_registry, 10, created_at: Time.zone.now) do |registry|
        registry.project = create(:project)
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:project) }
  end

  describe '.find_registry_differences' do
    let!(:secondary) { create(:geo_node) }
    let!(:synced_group) { create(:group) }
    let!(:nested_group) { create(:group, parent: synced_group) }
    let!(:project_1) { create(:project, group: synced_group) }
    let!(:project_2) { create(:project, group: nested_group) }
    let!(:project_3) { create(:project) }
    let!(:project_4) { create(:project) }
    let!(:project_5) { create(:project, :broken_storage) }
    let!(:project_6) { create(:project, :broken_storage) }

    before do
      stub_current_geo_node(secondary)
    end

    context 'untracked IDs' do
      before do
        create(:geo_project_registry, project_id: project_1.id)
        create(:geo_project_registry, :sync_failed, project_id: project_3.id)
        create(:geo_project_registry, project_id: project_5.id)
      end

      it 'includes project IDs without an entry on the tracking database' do
        range = Project.minimum(:id)..Project.maximum(:id)

        untracked_ids, _ = described_class.find_registry_differences(range)

        expect(untracked_ids).to match_array([project_2.id, project_4.id, project_6.id])
      end

      it 'excludes projects outside the ID range' do
        untracked_ids, _ = described_class.find_registry_differences(project_4.id..project_6.id)

        expect(untracked_ids).to match_array([project_4.id, project_6.id])
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'excludes project IDs that are not in selectively synced projects' do
          range = Project.minimum(:id)..Project.maximum(:id)

          untracked_ids, _ = described_class.find_registry_differences(range)

          expect(untracked_ids).to match_array([project_2.id])
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'excludes project IDs that are not in selectively synced projects' do
          range = Project.minimum(:id)..Project.maximum(:id)

          untracked_ids, _ = described_class.find_registry_differences(range)

          expect(untracked_ids).to match_array([project_6.id])
        end
      end
    end

    context 'unused tracked IDs' do
      context 'with an orphaned registry' do
        let!(:orphaned) { create(:geo_project_registry, project_id: project_1.id) }

        before do
          project_1.delete
        end

        it 'includes tracked IDs that do not exist in the model table' do
          range = project_1.id..project_1.id

          _, unused_tracked_ids = described_class.find_registry_differences(range)

          expect(unused_tracked_ids).to match_array([project_1.id])
        end

        it 'excludes IDs outside the ID range' do
          range = (project_1.id + 1)..Project.maximum(:id)

          _, unused_tracked_ids = described_class.find_registry_differences(range)

          expect(unused_tracked_ids).to be_empty
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        context 'with a tracked project' do
          context 'excluded from selective sync' do
            let!(:registry_entry) { create(:geo_project_registry, project_id: project_3.id) }

            it 'includes tracked project IDs that exist but are not in a selectively synced project' do
              range = project_3.id..project_3.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([project_3.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_project_registry, project_id: project_1.id) }

            it 'excludes tracked project IDs that are in selectively synced projects' do
              range = project_1.id..project_1.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        context 'with a tracked project' do
          let!(:registry_entry) { create(:geo_project_registry, project_id: project_1.id) }

          context 'excluded from selective sync' do
            it 'includes tracked project IDs that exist but are not in a selectively synced project' do
              range = project_1.id..project_1.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([project_1.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_project_registry, project_id: project_5.id) }

            it 'excludes tracked project IDs that are in selectively synced projects' do
              range = project_5.id..project_5.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end
    end
  end

  describe '.synced_repos' do
    it 'returns clean projects where last attempt to sync succeeded' do
      expected = []
      expected << create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      create(:geo_project_registry, :repository_syncing)
      expected << create(:geo_project_registry, :wiki_syncing)
      expected << create(:geo_project_registry, :wiki_sync_failed)
      create(:geo_project_registry, :repository_sync_failed)

      expect(described_class.synced_repos).to match_array(expected)
    end
  end

  describe '.synced_wikis' do
    it 'returns clean projects where last attempt to sync succeeded' do
      expected = []
      expected << create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      expected << create(:geo_project_registry, :repository_syncing)
      create(:geo_project_registry, :wiki_syncing)
      create(:geo_project_registry, :wiki_sync_failed)
      expected << create(:geo_project_registry, :repository_sync_failed)

      expect(described_class.synced_wikis).to match_array(expected)
    end
  end

  describe '.failed_repos' do
    it 'returns projects where last attempt to sync failed' do
      create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      create(:geo_project_registry, :repository_syncing)
      create(:geo_project_registry, :wiki_syncing)
      create(:geo_project_registry, :wiki_sync_failed)

      repository_sync_failed = create(:geo_project_registry, :repository_sync_failed)

      expect(described_class.failed_repos).to match_array([repository_sync_failed])
    end
  end

  describe '.failed_wikis' do
    it 'returns projects where last attempt to sync failed' do
      create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      create(:geo_project_registry, :repository_syncing)
      create(:geo_project_registry, :wiki_syncing)
      create(:geo_project_registry, :repository_sync_failed)

      wiki_sync_failed = create(:geo_project_registry, :wiki_sync_failed)

      expect(described_class.failed_wikis).to match_array([wiki_sync_failed])
    end
  end

  describe '.verified_repos' do
    it 'returns projects that verified' do
      create(:geo_project_registry, :repository_verification_failed)
      create(:geo_project_registry, :wiki_verified)
      create(:geo_project_registry, :wiki_verification_failed)

      repository_verified = create(:geo_project_registry, :repository_verified)

      expect(described_class.verified_repos).to match_array([repository_verified])
    end
  end

  describe '.verification_failed_repos' do
    it 'returns projects where last attempt to verify failed' do
      create(:geo_project_registry, :repository_verified)
      create(:geo_project_registry, :wiki_verified)
      create(:geo_project_registry, :wiki_verification_failed)

      repository_verification_failed = create(:geo_project_registry, :repository_verification_failed)

      expect(described_class.verification_failed_repos).to match_array([repository_verification_failed])
    end
  end

  describe '.verified_wikis' do
    it 'returns projects that verified' do
      create(:geo_project_registry, :repository_verification_failed)
      create(:geo_project_registry, :repository_verified)
      create(:geo_project_registry, :wiki_verification_failed)

      wiki_verified = create(:geo_project_registry, :wiki_verified)

      expect(described_class.verified_wikis).to match_array([wiki_verified])
    end
  end

  describe '.verification_failed_wikis' do
    it 'returns projects where last attempt to verify failed' do
      create(:geo_project_registry, :repository_verified)
      create(:geo_project_registry, :wiki_verified)
      create(:geo_project_registry, :repository_verification_failed)

      wiki_verification_failed = create(:geo_project_registry, :wiki_verification_failed)

      expect(described_class.verification_failed_wikis).to match_array([wiki_verification_failed])
    end
  end

  describe '.checksum_mismatch' do
    it 'returns projects where there is a checksum mismatch' do
      registry_repository_checksum_mismatch = create(:geo_project_registry, :repository_checksum_mismatch)
      regisry_wiki_checksum_mismatch = create(:geo_project_registry, :wiki_checksum_mismatch)
      create(:geo_project_registry)

      expect(described_class.checksum_mismatch).to match_array([regisry_wiki_checksum_mismatch, registry_repository_checksum_mismatch])
    end
  end

  describe '.retry_due' do
    it 'returns projects that should be synced' do
      create(:geo_project_registry, repository_retry_at: Date.yesterday, wiki_retry_at: Date.yesterday)
      tomorrow = create(:geo_project_registry, repository_retry_at: Date.tomorrow, wiki_retry_at: Date.tomorrow)
      create(:geo_project_registry)

      expect(described_class.retry_due).not_to include(tomorrow)
    end
  end

  describe '.with_search' do
    let_it_be(:project) { create(:project, description: 'kitten mittens') }
    let_it_be(:registry) { create(:geo_project_registry, project_id: project.id) }

    it 'returns project registries that refers to projects with a matching name' do
      expect(described_class.with_search(project.name)).to eq([registry])
    end

    it 'returns project registries that refers to projects with a matching name regardless of the casing' do
      expect(described_class.with_search(project.name.upcase)).to eq([registry])
    end

    it 'returns project registries that refers to projects with a matching description' do
      expect(described_class.with_search(project.description)).to eq([registry])
    end

    it 'returns project registries that refers to projects with a partially matching description' do
      expect(described_class.with_search('kitten')).to eq([registry])
    end

    it 'returns project registries that refers to projects with a matching description regardless of the casing' do
      expect(described_class.with_search('KITTEN')).to eq([registry])
    end

    it 'returns project registries that refers to projects with a matching path' do
      expect(described_class.with_search(project.path)).to eq([registry])
    end

    it 'returns project registries that refers to projects with a partially matching path' do
      expect(described_class.with_search(project.path[0..2])).to eq([registry])
    end

    it 'returns project registries that refers to projects with a matching path regardless of the casing' do
      expect(described_class.with_search(project.path.upcase)).to eq([registry])
    end
  end

  describe '.flag_repositories_for_reverify!' do
    it 'modified record to a reverify state' do
      registry = create(:geo_project_registry, :repository_verified)

      described_class.flag_repositories_for_reverify!

      expect(registry.reload).to have_attributes(
        repository_verification_checksum_sha: nil,
        last_repository_verification_failure: nil,
        repository_checksum_mismatch: false
      )
    end
  end

  describe '.flag_repositories_for_resync!' do
    it 'modified record to a resync state' do
      registry = create(:geo_project_registry, :synced)

      described_class.flag_repositories_for_resync!

      expect(registry.reload).to have_attributes(
        resync_repository: true,
        repository_verification_checksum_sha: nil,
        last_repository_verification_failure: nil,
        repository_checksum_mismatch: false,
        repository_verification_retry_count: nil,
        repository_retry_count: nil,
        repository_retry_at: nil
      )
    end
  end

  describe '.repository_out_of_date?' do
    let_it_be(:project) { create(:project) }

    context 'for a non-Geo setup' do
      it 'returns false' do
        expect(described_class.repository_out_of_date?(project.id)).to be_falsey
      end
    end

    context 'for a Geo setup' do
      before do
        stub_current_geo_node(current_node)
      end

      context 'for a Geo Primary' do
        let(:current_node) { create(:geo_node, :primary) }

        it 'returns false' do
          expect(described_class.repository_out_of_date?(project.id)).to be_falsey
        end
      end

      context 'for a Geo secondary' do
        let(:current_node) { create(:geo_node) }

        context 'where Primary node is not configured' do
          it 'returns false' do
            expect(described_class.repository_out_of_date?(project.id)).to be_falsey
          end
        end

        context 'where Primary node is configured' do
          before do
            create(:geo_node, :primary)
          end

          context 'where project_registry entry does not exist' do
            it 'returns true' do
              expect(described_class.repository_out_of_date?(project.id)).to be_truthy
            end
          end

          context 'where project_registry entry does exist' do
            context 'where last_repository_updated_at is not set' do
              it 'returns false' do
                registry = create(:geo_project_registry, :synced)
                registry.project.update!(last_repository_updated_at: nil)

                expect(described_class.repository_out_of_date?(registry.project_id)).to be_falsey
              end
            end

            context 'where last_repository_updated_at is set' do
              context 'where last_repository_successful_sync_at is not set' do
                it 'returns true' do
                  registry = create(:geo_project_registry, :repository_sync_failed)

                  expect(described_class.repository_out_of_date?(registry.project_id)).to be_truthy
                end
              end

              context 'where last_repository_successful_sync_at is set', :freeze_time do
                let_it_be(:project_repository_state) { create(:repository_state, project: project) }

                where(:project_last_updated, :project_state_last_updated, :project_registry_last_synced, :expected_out_of_date?) do
                  Time.current - 3.minutes | nil                      | Time.current - 5.minutes | true
                  Time.current - 3.minutes | nil                      | Time.current - 1.minute  | false
                  Time.current - 3.minutes | Time.current             | Time.current - 1.minute  | true
                  Time.current - 3.minutes | Time.current - 2.minutes | Time.current - 1.minute  | false
                  Time.current - 3.minutes | Time.current             | Time.current - 5.minutes | true
                end

                with_them do
                  before do
                    project.update!(last_repository_updated_at: project_last_updated)
                    project_repository_state.update!(last_repository_updated_at: project_state_last_updated)
                    create(:geo_project_registry, :synced, project: project, last_repository_successful_sync_at: project_registry_last_synced)
                  end

                  it 'returns the expected value' do
                    expect(described_class.repository_out_of_date?(project.id)).to eq(expected_out_of_date?)
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  describe '#repository_sync_due?' do
    where(:last_synced_at, :resync, :retry_at, :expected) do
      now = Time.current
      past = now - 1.year
      future = now + 1.year

      nil    | false | nil    | true
      nil    | true  | nil    | true
      nil    | true  | past   | true
      nil    | true  | future | true

      past   | false | nil    | false
      past   | true  | nil    | true
      past   | true  | past   | true
      past   | true  | future | false

      future | false | nil    | false
      future | true  | nil    | false
      future | true  | past   | false
      future | true  | future | false
    end

    with_them do
      before do
        registry.update!(
          last_repository_synced_at: last_synced_at,
          resync_repository: resync,
          repository_retry_at: retry_at
        )
      end

      it { expect(registry.repository_sync_due?(Time.current)).to eq(expected) }
    end
  end

  describe '#wiki_sync_due?' do
    where(:last_synced_at, :resync, :retry_at, :expected) do
      now = Time.current
      past = now - 1.year
      future = now + 1.year

      nil    | false | nil    | true
      nil    | true  | nil    | true
      nil    | true  | past   | true
      nil    | true  | future | true

      past   | false | nil    | false
      past   | true  | nil    | true
      past   | true  | past   | true
      past   | true  | future | false

      future | false | nil    | false
      future | true  | nil    | false
      future | true  | past   | false
      future | true  | future | false
    end

    with_them do
      before do
        registry.update!(
          last_wiki_synced_at: last_synced_at,
          resync_wiki: resync,
          wiki_retry_at: retry_at
        )
      end

      it { expect(registry.wiki_sync_due?(Time.current)).to eq(expected) }
    end
  end

  context 'redis shared state', :redis do
    after do
      subject.reset_syncs_since_gc!
    end

    describe '#syncs_since_gc' do
      context 'without any sync' do
        it 'returns 0' do
          expect(subject.syncs_since_gc).to eq(0)
        end
      end

      context 'with a number of syncs' do
        it 'returns the number of syncs' do
          2.times { Geo::ProjectHousekeepingService.new(subject.project).increment! }

          expect(subject.syncs_since_gc).to eq(2)
        end
      end
    end

    describe '#increment_syncs_since_gc' do
      it 'increments the number of syncs since the last GC' do
        3.times { subject.increment_syncs_since_gc! }

        expect(subject.syncs_since_gc).to eq(3)
      end
    end

    describe '#reset_syncs_since_gc' do
      it 'resets the number of syncs since the last GC' do
        3.times { subject.increment_syncs_since_gc! }

        subject.reset_syncs_since_gc!

        expect(subject.syncs_since_gc).to eq(0)
      end
    end
  end

  describe '#start_sync!' do
    around do |example|
      freeze_time do
        example.run
      end
    end

    context 'for a repository' do
      let(:type) { 'repository' }

      it 'sets last_repository_synced_at to now' do
        subject.start_sync!(type)

        expect(subject.last_repository_synced_at).to be_like_time(Time.current)
      end

      context 'when repository_retry_count is nil' do
        it 'sets repository_retry_count to 0' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.repository_retry_count }.from(nil).to(0)
        end
      end
    end

    context 'for a wiki' do
      let(:type) { 'wiki' }

      it 'sets last_wiki_synced_at to now' do
        subject.start_sync!(type)

        expect(subject.last_wiki_synced_at).to be_like_time(Time.current)
      end

      context 'when wiki_retry_count is nil' do
        it 'sets wiki_retry_count to 0' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.wiki_retry_count }.from(nil).to(0)
        end
      end
    end
  end

  describe '#finish_sync!' do
    context 'for a repository' do
      let(:type) { 'repository' }

      before do
        subject.start_sync!(type)
        subject.update!(repository_retry_at: 1.day.from_now,
                        repository_retry_count: 1,
                        force_to_redownload_repository: true,
                        last_repository_sync_failure: 'foo',
                        repository_verification_checksum_sha: 'abc123',
                        repository_checksum_mismatch: true,
                        last_repository_verification_failure: 'bar',
                        repository_verification_retry_count: 1)
      end

      it 'sets last_repository_successful_sync_at to now' do
        freeze_time do
          subject.finish_sync!(type)

          expect(subject.reload.last_repository_successful_sync_at).to be_within(1).of(Time.current)
        end
      end

      it 'resets sync state' do
        subject.finish_sync!(type)

        expect(subject.reload).to have_attributes(
          resync_repository: false,
          repository_retry_count: nil,
          repository_retry_at: nil,
          force_to_redownload_repository: false,
          last_repository_sync_failure: nil,
          repository_missing_on_primary: false
        )
      end

      it 'resets verification state' do
        subject.finish_sync!(type)

        expect(subject.reload).to have_attributes(
          repository_verification_checksum_sha: nil,
          repository_checksum_mismatch: false,
          last_repository_verification_failure: nil
        )
      end

      it 'does not reset repository_verification_retry_count' do
        subject.finish_sync!(type)

        expect(subject.reload.repository_verification_retry_count).to eq 1
      end

      context 'when a repository was missing on primary' do
        it 'sets repository_missing_on_primary as true' do
          subject.finish_sync!(type, true)

          expect(subject.reload.repository_missing_on_primary).to be true
        end
      end

      context 'when a repository sync was scheduled after the last sync began' do
        before do
          subject.update!(resync_repository_was_scheduled_at: subject.last_repository_synced_at + 1.minute)

          subject.finish_sync!(type)
        end

        it 'does not reset resync_repository' do
          expect(subject.reload.resync_repository).to be true
        end

        it 'resets the other sync state fields' do
          expect(subject.reload).to have_attributes(
            repository_retry_count: nil,
            repository_retry_at: nil,
            force_to_redownload_repository: false,
            last_repository_sync_failure: nil,
            repository_missing_on_primary: false
          )
        end

        it 'resets the verification state' do
          expect(subject.reload).to have_attributes(
            repository_verification_checksum_sha: nil,
            repository_checksum_mismatch: false,
            last_repository_verification_failure: nil
          )
        end

        it 'does not reset repository_verification_retry_count' do
          expect(subject.reload.repository_verification_retry_count).to eq 1
        end
      end
    end

    context 'for a wiki' do
      let(:type) { 'wiki' }

      before do
        subject.start_sync!(type)
        subject.update!(wiki_retry_at: 1.day.from_now,
                        wiki_retry_count: 1,
                        force_to_redownload_wiki: true,
                        last_wiki_sync_failure: 'foo',
                        wiki_verification_checksum_sha: 'abc123',
                        wiki_checksum_mismatch: true,
                        last_wiki_verification_failure: 'bar',
                        wiki_verification_retry_count: 1)
      end

      it 'sets last_wiki_successful_sync_at to now' do
        freeze_time do
          subject.finish_sync!(type)

          expect(subject.reload.last_wiki_successful_sync_at).to be_within(1).of(Time.current)
        end
      end

      it 'resets sync state' do
        subject.finish_sync!(type)

        expect(subject.reload).to have_attributes(
          resync_wiki: false,
          wiki_retry_count: nil,
          wiki_retry_at: nil,
          force_to_redownload_wiki: false,
          last_wiki_sync_failure: nil,
          wiki_missing_on_primary: false
        )
      end

      it 'resets verification state' do
        subject.finish_sync!(type)

        expect(subject.reload).to have_attributes(
          wiki_verification_checksum_sha: nil,
          wiki_checksum_mismatch: false,
          last_wiki_verification_failure: nil
        )
      end

      it 'does not reset wiki_verification_retry_count' do
        subject.finish_sync!(type)

        expect(subject.reload.wiki_verification_retry_count).to eq 1
      end

      context 'when a wiki was missing on primary' do
        it 'sets wiki_missing_on_primary as true' do
          subject.finish_sync!(type, true)

          expect(subject.reload.wiki_missing_on_primary).to be true
        end
      end

      context 'when a wiki sync was scheduled after the last sync began' do
        before do
          subject.update!(resync_wiki_was_scheduled_at: subject.last_wiki_synced_at + 1.minute)

          subject.finish_sync!(type)
        end

        it 'does not reset resync_wiki' do
          expect(subject.reload.resync_wiki).to be true
        end

        it 'resets the other sync state fields' do
          expect(subject.reload).to have_attributes(
            wiki_retry_count: nil,
            wiki_retry_at: nil,
            force_to_redownload_wiki: false,
            last_wiki_sync_failure: nil,
            wiki_missing_on_primary: false
          )
        end

        it 'resets the verification state' do
          expect(subject.reload).to have_attributes(
            wiki_verification_checksum_sha: nil,
            wiki_checksum_mismatch: false,
            last_wiki_verification_failure: nil
          )
        end

        it 'does not reset wiki_verification_retry_count' do
          expect(subject.reload.wiki_verification_retry_count).to eq 1
        end
      end
    end
  end

  describe '#fail_sync!' do
    context 'for a repository' do
      let(:type) { 'repository' }
      let(:message) { 'foo' }
      let(:error) { StandardError.new('bar') }

      before do
        subject.start_sync!(type)
        subject.update!(resync_repository: false,
                        last_repository_sync_failure: 'foo')
      end

      it 'sets repository_retry_at to a future time' do
        subject.update!(repository_retry_count: 0)

        subject.fail_sync!(type, message, error)

        expect(subject.repository_retry_at > Time.current).to be(true)
      end

      it 'ensures repository_retry_at is capped at one hour' do
        subject.update!(repository_retry_count: 31)

        subject.fail_sync!(type, message, error)

        expect(subject).to have_attributes(
          repository_retry_at: be_within(100.seconds).of(1.hour.from_now),
          repository_retry_count: 32
        )
      end

      it 'sets resync_repository to true' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.resync_repository).to be true
      end

      it 'includes message in last_repository_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_repository_sync_failure).to include(message)
      end

      it 'includes error message in last_repository_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_repository_sync_failure).to include(error.message)
      end

      it 'increments repository_retry_count' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.repository_retry_count).to eq(1)
      end

      it 'optionally updates other attributes' do
        subject.fail_sync!(type, message, error, { force_to_redownload_repository: true })

        expect(subject.reload.force_to_redownload_repository).to be true
      end

      context 'when repository_retry_count is 0' do
        before do
          subject.update!(repository_retry_count: 0)
        end

        it 'increments repository_retry_count' do
          expect do
            subject.fail_sync!(type, message, error)
          end.to change { subject.repository_retry_count }.by(1)
        end
      end

      context 'when repository_retry_count is 1' do
        before do
          subject.update!(repository_retry_count: 1)
        end

        it 'increments repository_retry_count' do
          expect do
            subject.fail_sync!(type, message, error)
          end.to change { subject.repository_retry_count }.by(1)
        end
      end
    end

    context 'for a wiki' do
      let(:type) { 'wiki' }
      let(:message) { 'foo' }
      let(:error) { StandardError.new('bar') }

      before do
        subject.start_sync!(type)
        subject.update!(resync_wiki: false,
                        last_wiki_sync_failure: 'foo')
      end

      it 'sets wiki_retry_at to a future time' do
        subject.update!(wiki_retry_count: 0)

        subject.fail_sync!(type, message, error)

        expect(subject.wiki_retry_at > Time.current).to be(true)
      end

      it 'ensures wiki_retry_at is capped at one hour' do
        subject.update!(wiki_retry_count: 31)

        subject.fail_sync!(type, message, error)

        expect(subject).to have_attributes(
          wiki_retry_at: be_within(100.seconds).of(1.hour.from_now),
          wiki_retry_count: 32
        )
      end

      it 'sets resync_wiki to true' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.resync_wiki).to be true
      end

      it 'includes message in last_wiki_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_wiki_sync_failure).to include(message)
      end

      it 'includes error message in last_wiki_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_wiki_sync_failure).to include(error.message)
      end

      it 'increments wiki_retry_count' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.wiki_retry_count).to eq(1)
      end

      it 'optionally updates other attributes' do
        subject.fail_sync!(type, message, error, { force_to_redownload_wiki: true })

        expect(subject.reload.force_to_redownload_wiki).to be true
      end

      context 'when wiki_retry_count is 0' do
        before do
          subject.update!(wiki_retry_count: 0)
        end

        it 'increments wiki_retry_count' do
          expect do
            subject.fail_sync!(type, message, error)
          end.to change { subject.wiki_retry_count }.by(1)
        end
      end

      context 'when wiki_retry_count is 1' do
        before do
          subject.update!(wiki_retry_count: 1)
        end

        it 'increments wiki_retry_count' do
          expect do
            subject.fail_sync!(type, message, error)
          end.to change { subject.wiki_retry_count }.by(1)
        end
      end
    end
  end

  describe '#repository_created!' do
    let(:event) { double(:event, wiki_path: nil) }

    before do
      subject.repository_created!(event)
    end

    it 'sets resync_repository to true' do
      expect(subject.resync_repository).to be true
    end

    context 'when the RepositoryCreatedEvent wiki_path is present' do
      let(:event) { double(:event, wiki_path: 'foo') }

      it 'sets resync_wiki to true' do
        expect(subject.resync_wiki).to be true
      end
    end

    context 'when the RepositoryCreatedEvent wiki_path is blank' do
      it 'sets resync_wiki to false' do
        expect(subject.resync_wiki).to be false
      end
    end
  end

  describe '#repository_updated!' do
    context 'for a repository' do
      let(:event) { double(:event, source: 'repository') }

      before do
        subject.update!(resync_repository: false,
                        repository_verification_checksum_sha: 'abc123',
                        repository_checksum_mismatch: true,
                        last_repository_verification_failure: 'foo',
                        resync_repository_was_scheduled_at: nil,
                        repository_retry_at: 1.hour.from_now,
                        repository_retry_count: 1,
                        repository_verification_retry_count: 1)

        subject.repository_updated!(event.source, Time.current)
      end

      it 'resets sync state' do
        expect(subject.reload).to have_attributes(
          resync_repository: true,
          repository_retry_count: nil,
          repository_retry_at: nil,
          force_to_redownload_repository: nil,
          last_repository_sync_failure: nil,
          repository_missing_on_primary: nil,
          resync_repository_was_scheduled_at: be_within(1.minute).of(Time.current)
        )
      end

      it 'resets verification state' do
        expect(subject).to have_attributes(
          repository_verification_checksum_sha: nil,
          repository_checksum_mismatch: false,
          last_repository_verification_failure: nil,
          repository_verification_retry_count: nil
        )
      end
    end

    context 'for a wiki' do
      let(:event) { double(:event, source: 'wiki') }

      before do
        subject.update!(resync_wiki: false,
                        wiki_verification_checksum_sha: 'abc123',
                        wiki_checksum_mismatch: true,
                        last_wiki_verification_failure: 'foo',
                        resync_wiki_was_scheduled_at: nil,
                        wiki_retry_at: 1.hour.from_now,
                        wiki_retry_count: 1,
                        wiki_verification_retry_count: 1)

        subject.repository_updated!(event.source, Time.current)
      end

      it 'resets sync state' do
        expect(subject.reload).to have_attributes(
          resync_wiki: true,
          wiki_retry_count: nil,
          wiki_retry_at: nil,
          force_to_redownload_wiki: nil,
          last_wiki_sync_failure: nil,
          wiki_missing_on_primary: nil,
          resync_wiki_was_scheduled_at: be_within(1.minute).of(Time.current)
        )
      end

      it 'resets verification state' do
        expect(subject).to have_attributes(
          wiki_verification_checksum_sha: nil,
          wiki_checksum_mismatch: false,
          last_wiki_verification_failure: nil,
          wiki_verification_retry_count: nil
        )
      end
    end
  end

  describe '#reset_checksum!' do
    it 'resets repository/wiki verification state' do
      subject.update!(
        repository_verification_checksum_sha: 'abc123',
        wiki_verification_checksum_sha: 'abc123',
        repository_checksum_mismatch: true,
        wiki_checksum_mismatch: true,
        last_repository_verification_failure: 'foo',
        last_wiki_verification_failure: 'foo',
        repository_verification_retry_count: 1,
        wiki_verification_retry_count: 1
      )

      subject.reset_checksum!

      expect(subject).to have_attributes(
        repository_verification_checksum_sha: nil,
        wiki_verification_checksum_sha: nil,
        repository_checksum_mismatch: false,
        wiki_checksum_mismatch: false,
        last_repository_verification_failure: nil,
        last_wiki_verification_failure: nil,
        repository_verification_retry_count: nil,
        wiki_verification_retry_count: nil
      )
    end
  end

  describe '#repository_verification_pending?' do
    it 'returns true when outdated' do
      registry = create(:geo_project_registry, :repository_verification_outdated)

      expect(registry.repository_verification_pending?).to be_truthy
    end

    it 'returns true when we are missing checksum sha' do
      registry = create(:geo_project_registry, :repository_verification_failed)

      expect(registry.repository_verification_pending?).to be_truthy
    end

    it 'returns false when checksum is present' do
      registry = create(:geo_project_registry, :repository_verified)

      expect(registry.repository_verification_pending?).to be_falsey
    end
  end

  describe '#wiki_verification_pending?' do
    it 'returns true when outdated' do
      registry = create(:geo_project_registry, :wiki_verification_outdated)

      expect(registry.wiki_verification_pending?).to be_truthy
    end

    it 'returns true when we are missing checksum sha' do
      registry = create(:geo_project_registry, :wiki_verification_failed)

      expect(registry.wiki_verification_pending?).to be_truthy
    end

    it 'returns false when checksum is present' do
      registry = create(:geo_project_registry, :wiki_verified)

      expect(registry.wiki_verification_pending?).to be_falsey
    end
  end

  describe 'pending_verification?' do
    it 'returns true when either wiki or repository verification is pending' do
      repo_registry = create(:geo_project_registry, :repository_verification_outdated)
      wiki_registry = create(:geo_project_registry, :wiki_verification_failed)

      expect(repo_registry.pending_verification?).to be_truthy
      expect(wiki_registry.pending_verification?).to be_truthy
    end

    it 'returns false when both wiki and repository verification is present' do
      registry = create(:geo_project_registry, :repository_verified, :wiki_verified)

      expect(registry.pending_verification?).to be_falsey
    end
  end

  describe 'pending_synchronization?' do
    it 'returns true when either wiki or repository synchronization is pending' do
      repo_registry = create(:geo_project_registry)
      wiki_registry = create(:geo_project_registry)

      expect(repo_registry.pending_synchronization?).to be_truthy
      expect(wiki_registry.pending_synchronization?).to be_truthy
    end

    it 'returns false when both wiki and repository synchronization is present' do
      registry = create(:geo_project_registry, :synced)

      expect(registry.pending_synchronization?).to be_falsey
    end
  end

  describe '#flag_repository_for_reverify!' do
    it 'modified record to a reverify state' do
      registry = create(:geo_project_registry, :repository_verified)
      registry.flag_repository_for_reverify!

      expect(registry).to have_attributes(
        repository_verification_checksum_sha: nil,
        last_repository_verification_failure: nil,
        repository_checksum_mismatch: false
      )
    end
  end

  describe '#flag_repository_for_resync!' do
    it 'modified record to a resync state' do
      registry = create(:geo_project_registry, :synced)
      registry.flag_repository_for_resync!

      expect(registry).to have_attributes(
        resync_repository: true,
        repository_verification_checksum_sha: nil,
        last_repository_verification_failure: nil,
        repository_checksum_mismatch: false,
        repository_verification_retry_count: nil,
        repository_retry_count: nil,
        repository_retry_at: nil
      )
    end
  end

  describe '#flag_repository_for_redownload!' do
    it 'modified record to a redownload state' do
      registry = create(:geo_project_registry, :repository_verified)
      registry.flag_repository_for_redownload!

      expect(registry).to have_attributes(
        resync_repository: true,
        force_to_redownload_repository: true
      )
    end
  end

  describe '#candidate_for_redownload?' do
    context 'when feature flag geo_deprecate_redownload is enabled' do
      it 'returns false when repository_retry_count is 1 or less' do
        registry = create(:geo_project_registry, :sync_failed)

        expect(registry.candidate_for_redownload?).to be_falsey
      end

      it 'returns false when repository_retry_count is > 1' do
        registry = create(:geo_project_registry, :sync_failed, repository_retry_count: 2)

        expect(registry.candidate_for_redownload?).to be_falsey
      end
    end

    context 'when feature flag geo_deprecate_redownload is disabled' do
      before do
        stub_feature_flags(geo_deprecate_redownload: false)
      end

      it 'returns false when repository_retry_count is 1 or less' do
        registry = create(:geo_project_registry, :sync_failed)

        expect(registry.candidate_for_redownload?).to be_falsey
      end

      it 'returns true when repository_retry_count is > 1' do
        registry = create(:geo_project_registry, :sync_failed, repository_retry_count: 2)

        expect(registry.candidate_for_redownload?).to be_truthy
      end
    end
  end

  describe '#synchronization_state' do
    it 'returns :never when no attempt to sync has ever been done' do
      registry = create(:geo_project_registry)

      expect(registry.synchronization_state).to eq(:never)
    end

    it 'returns :failed when there is an existing error logged' do
      registry = create(:geo_project_registry, :sync_failed)

      expect(registry.synchronization_state).to eq(:failed)
    end

    it 'returns :pending when there is an existing error logged' do
      registry = create(:geo_project_registry, :synced, :repository_dirty)

      expect(registry.synchronization_state).to eq(:pending)
    end

    it 'returns :synced when its fully synced and there is no pending action or existing error' do
      registry = create(:geo_project_registry, :synced, :repository_verified)

      expect(registry.synchronization_state).to eq(:synced)
    end
  end

  describe 'repository_has_successfully_synced?' do
    context 'when repository has never successfully synced' do
      it 'returns false' do
        registry = create(:geo_project_registry, last_repository_successful_sync_at: nil)

        expect(registry.repository_has_successfully_synced?).to be_falsey
      end
    end

    context 'when repository has successfully synced' do
      it 'returns true' do
        registry = create(:geo_project_registry, last_repository_successful_sync_at: Time.current)

        expect(registry.repository_has_successfully_synced?).to be_truthy
      end
    end
  end

  describe 'should_be_redownloaded?' do
    context 'when type is invalid' do
      it 'raises ArgumentError' do
        registry = build(:geo_project_registry)

        expect do
          registry.should_be_redownloaded?(:invalid_type)
        end.to raise_error(ArgumentError)
      end
    end

    context 'when type is repository' do
      where(:force_to_redownload_repository, :repository_retry_count, :expected) do
        false | nil | false
        false | 0   | false
        false | 1   | false
        false | 10  | false
        false | 11  | true
        false | 12  | false
        false | 13  | true
        false | 14  | false
        false | 101 | true
        false | 102 | false
        true  | nil | true
        true  | 0   | true
        true  | 11  | true
      end

      with_them do
        it "returns the expected boolean" do
          registry = build(:geo_project_registry, repository_retry_count: repository_retry_count, force_to_redownload_repository: force_to_redownload_repository)

          expect(registry.should_be_redownloaded?(:repository)).to eq(expected)
        end
      end
    end

    context 'when type is wiki' do
      where(:force_to_redownload_wiki, :wiki_retry_count, :expected) do
        false | nil | false
        false | 0   | false
        false | 1   | false
        false | 10  | false
        false | 11  | true
        false | 12  | false
        false | 13  | true
        false | 14  | false
        false | 101 | true
        false | 102 | false
        true  | nil | true
        true  | 0   | true
        true  | 11  | true
      end

      with_them do
        it "returns the expected boolean" do
          registry = build(:geo_project_registry, wiki_retry_count: wiki_retry_count, force_to_redownload_wiki: force_to_redownload_wiki)

          expect(registry.should_be_redownloaded?(:wiki)).to eq(expected)
        end
      end
    end
  end
end
