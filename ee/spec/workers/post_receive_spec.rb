# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PostReceive do
  include AfterNextHelpers

  let(:changes) { "123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }
  let(:changes_with_master) { "#{changes}\n423423 797823 refs/heads/master" }
  let(:wrongly_encoded_changes) { changes.encode("ISO-8859-1").force_encoding("UTF-8") }
  let(:base64_changes) { Base64.encode64(wrongly_encoded_changes) }
  let(:base64_changes_with_master) { Base64.encode64(changes_with_master) }
  let(:gl_repository) { "project-#{project.id}" }
  let(:key) { create(:key, user: project.owner) }
  let(:key_id) { key.shell_id }
  let(:project) { create(:project, :repository) }

  describe "#process_project_changes" do
    context 'after project changes hooks' do
      let(:fake_hook_data) { Hash.new(event_name: 'repository_update') }

      before do
        allow(RepositoryPushAuditEventWorker).to receive(:perform_async)
        allow_next(Gitlab::DataBuilder::Repository)
          .to receive(:update).and_return(fake_hook_data)

        # silence hooks so we can isolate
        allow_next(Key).to receive(:post_create_hook).and_return(true)

        expect_next(Git::TagPushService).to receive(:execute).and_return(true)
        expect_next(Git::BranchPushService).to receive(:execute).and_return(true)
      end

      context 'when DB is readonly' do
        before do
          allow(Gitlab::Database).to receive(:read_only?) { true }
        end

        it 'does not call RepositoryPushAuditEventWorker' do
          expect(::RepositoryPushAuditEventWorker).not_to receive(:perform_async)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end

      context 'when DB is not readonly' do
        before do
          allow(Gitlab::Database).to receive(:read_only?) { false }
        end

        it 'calls RepositoryPushAuditEventWorker' do
          expected_changes = [
            { after: '789012', before: '123456', ref: 'refs/heads/tést' },
            { after: '210987', before: '654321', ref: 'refs/tags/tag' }
          ]

          expect(::RepositoryPushAuditEventWorker).to receive(:perform_async)
            .with(expected_changes, project.id, project.owner.id)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end

        context 'when feature flag is off' do
          before do
            stub_feature_flags(repository_push_audit_event: false)
          end

          it 'does not call RepositoryPushAuditEventWorker' do
            expect(::RepositoryPushAuditEventWorker).not_to receive(:perform_async)

            described_class.new.perform(gl_repository, key_id, base64_changes)
          end
        end
      end

      it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node' do
        allow(Gitlab::Geo).to receive(:primary?) { true }

        expect(::Geo::RepositoryUpdatedService).to get_executed

        described_class.new.perform(gl_repository, key_id, base64_changes)
      end

      it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node' do
        allow(Gitlab::Geo).to receive(:primary?) { false }

        expect_next_instance_of(::Geo::RepositoryUpdatedService).never

        described_class.new.perform(gl_repository, key_id, base64_changes)
      end
    end
  end

  describe '#process_wiki_changes' do
    let(:wiki) { build(:project_wiki, project: project) }
    let(:gl_repository) { wiki.repository.repo_type.identifier_for_container(wiki) }

    it 'calls Git::WikiPushService#execute' do
      expect_next(::Git::WikiPushService).to receive(:execute)

      described_class.new.perform(gl_repository, key_id, base64_changes)
    end

    context 'assuming calls to process_changes are successful' do
      before do
        # We instantiate the wiki here so that expect_next(ProjectWiki) captures the right thing.
        project.wiki

        allow_next(Git::WikiPushService).to receive(:execute)
      end

      it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node' do
        allow(Gitlab::Geo).to receive(:primary?) { true }

        expect(::Geo::RepositoryUpdatedService).to get_executed

        described_class.new.perform(gl_repository, key_id, base64_changes)
      end

      it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node' do
        allow(Gitlab::Geo).to receive(:primary?) { false }

        expect_next_instance_of(::Geo::RepositoryUpdatedService).never

        described_class.new.perform(gl_repository, key_id, base64_changes)
      end
    end

    context 'with a group wiki' do
      let_it_be(:group) { create(:group) }

      let(:wiki) { build(:group_wiki, group: group) }

      it 'calls Git::WikiPushService#execute' do
        expect_next_instance_of(::Git::WikiPushService) do |service|
          expect(service).to receive(:execute)
        end

        described_class.new.perform(gl_repository, key_id, base64_changes)
      end

      context 'when on a Geo primary node' do
        before do
          allow(Gitlab::Geo).to receive(:primary?) { true }
        end

        it 'does not call Geo::RepositoryUpdatedService' do
          expect_next_instance_of(::Geo::RepositoryUpdatedService).never

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end

        context 'when wiki is a project wiki' do
          let(:wiki) { build(:project_wiki, project: project) }

          it 'does not call replicator to update Geo' do
            expect_next_instance_of(Geo::GroupWikiRepositoryReplicator).never

            described_class.new.perform(gl_repository, key_id, base64_changes)
          end
        end

        context 'when group_wiki_repository does not exist' do
          it 'does not call replicator to update Geo' do
            expect(group.group_wiki_repository).to be_nil

            expect_next_instance_of(Geo::GroupWikiRepositoryReplicator).never

            described_class.new.perform(gl_repository, key_id, base64_changes)
          end
        end

        context 'when group_wiki_repository exists' do
          it 'calls replicator to update Geo' do
            wiki.create_wiki_repository

            expect(group.group_wiki_repository).to be_present
            expect_next_instance_of(Geo::GroupWikiRepositoryReplicator) do |instance|
              expect(instance).to receive(:handle_after_update)
            end

            described_class.new.perform(gl_repository, key_id, base64_changes)
          end
        end
      end

      context 'when not on a Geo primary node' do
        it 'does not call replicator to update Geo' do
          wiki.create_wiki_repository

          expect(group.group_wiki_repository).to be_present
          expect_next_instance_of(Geo::GroupWikiRepositoryReplicator).never

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end
    end
  end
end
