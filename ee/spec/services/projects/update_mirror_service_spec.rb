# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateMirrorService do
  let(:project) do
    create(:project, :repository, :mirror, import_url: Project::UNKNOWN_IMPORT_URL, only_mirror_protected_branches: false)
  end

  subject(:service) { described_class.new(project, project.first_owner) }

  describe "#execute" do
    context 'unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does nothing' do
        expect(project).not_to receive(:fetch_mirror)

        result = service.execute

        expect(result[:status]).to eq(:success)
      end
    end

    it "fetches the upstream repository" do
      expect(project).to receive(:fetch_mirror)

      service.execute
    end

    it 'runs project housekeeping' do
      stub_fetch_mirror(project)

      expect_next_instance_of(Repositories::HousekeepingService) do |svc|
        expect(svc).to receive(:increment!)
        expect(svc).to receive(:needed?).and_return(true)
        expect(svc).to receive(:execute)
      end

      service.execute
    end

    it 'rescues exceptions from Repository#ff_merge' do
      stub_fetch_mirror(project)

      expect(project.repository).to receive(:ff_merge).and_raise(Gitlab::Git::PreReceiveError)

      expect { service.execute }.not_to raise_error
    end

    it "returns success when updated succeeds" do
      stub_fetch_mirror(project)

      result = service.execute

      expect(result[:status]).to eq(:success)
    end

    it "disables mirroring protected branches only by default" do
      new_project = create(:project, :repository, :mirror, import_url: Project::UNKNOWN_IMPORT_URL)

      expect(new_project.only_mirror_protected_branches).to be_falsey
    end

    context 'when mirror user is blocked' do
      before do
        project.mirror_user.block
      end

      it 'fails and returns error status' do
        expect(service.execute[:status]).to eq(:error)
      end
    end

    context "when the URL is blocked" do
      before do
        allow(Gitlab::UrlBlocker).to receive(:blocked_url?).and_return(true)

        stub_fetch_mirror(project)
      end

      it "fails and returns error status" do
        expect(service.execute[:status]).to eq(:error)
      end
    end

    context "when given URLs contain escaped elements" do
      it_behaves_like "URLs containing escaped elements return expected status" do
        let(:result) { service.execute }

        before do
          allow(project).to receive(:import_url).and_return(url)

          stub_fetch_mirror(project)
        end
      end
    end

    context 'updating tags', :aggregate_failures do
      it 'creates new tags, expiring cache if there are tag changes' do
        stub_fetch_mirror(project)

        expect(project.repository).to receive(:expire_tags_cache).and_call_original

        expect(service.execute).to eq(status: :success)

        expect(project.repository.tag_names).to include('new-tag')
      end

      it 'does not expire cache if there are no tag changes' do
        stub_fetch_mirror(project, tags_changed: false)

        expect(project.repository).not_to receive(:expire_tags_cache)

        expect(service.execute).to eq(status: :success)
      end

      it 'only invokes Git::TagPushService for tags pointing to commits' do
        stub_fetch_mirror(project)

        allow(Git::TagPushService).to receive(:new).and_call_original
        expect(Git::TagPushService).to receive(:new)
          .with(project, project.first_owner, change: hash_including(ref: 'refs/tags/new-tag'), mirror_update: true)
          .and_return(double(execute: true))

        expect(service.execute).to eq(status: :success)
      end

      describe 'Protected tags mirroring' do
        context 'when user has permissions to create a protected tag' do
          let!(:protected_tag) { create(:protected_tag, project: project, name: 'protected-tag') }

          it 'creates the protected tag' do
            stub_fetch_mirror(project)

            expect(project.repository).to receive(:expire_tags_cache).and_call_original
            expect(Git::TagPushService).to receive(:new).and_call_original.twice

            expect(service.execute).to eq(status: :success)

            expect(project.repository.tag_names).to include('new-tag', 'protected-tag')
          end
        end

        context 'when user cannot create a protected tag' do
          let!(:protected_tag) { create(:protected_tag, :no_one_can_create, project: project, name: 'protected-tag') }

          it 'creates only tags that user can create' do
            stub_fetch_mirror(project)

            expect(Git::TagPushService).to receive(:new).and_call_original.once

            expect(service.execute).to eq(
              message: "You are not allowed to create tags: 'protected-tag' as they are protected.",
              status: :error
            )
            expect(project.repository.tag_names).not_to include('protected-tag')
            expect(project.repository.tag_names).to include('new-tag')
          end
        end
      end
    end

    context 'when repository is in read-only mode' do
      before do
        project.update_attribute(:repository_read_only, true)
      end

      it 'does not run if repository is set to read-only' do
        expect(service).not_to receive(:update_tags)
        expect(service).not_to receive(:update_branches)

        expect(service.execute).to be_truthy
      end
    end

    context 'when tags on mirror are modified' do
      let(:mirror_project) { create(:project, :repository) }
      let(:mirror_path) { Gitlab::GitalyClient::StorageSettings.allow_disk_access { File.join(TestEnv.repos_path, mirror_project.repository.relative_path) } }
      let!(:mirror_modified_tag_sha) { modify_tag(mirror_project.repository, 'v1.0.0') }
      let!(:mirror_modified_branch_sha) { modify_branch(mirror_project.repository, 'feature') }
      let(:project) do
        create(:project, :repository, :mirror, import_url: Project::UNKNOWN_IMPORT_URL, only_mirror_protected_branches: false)
      end

      before do
        allow(project).to receive(:import_url).and_return(mirror_path)

        allow(Gitlab::UrlBlocker).to receive(:blocked_url?).and_return(false)
      end

      context 'when mirror_overwrites_diverged_branches is true' do
        before do
          project.mirror_overwrites_diverged_branches = true
        end

        it 'updates the tag' do
          result = service.execute

          expect(result[:status]).to eq(:success)
          expect(project.repository.find_tag('v1.0.0').dereferenced_target.id).to eq(mirror_modified_tag_sha)
        end

        it 'updates the modified branch' do
          service.execute

          expect(project.repository.find_branch('feature').dereferenced_target.id).to eq(mirror_modified_branch_sha)
        end

        it 'returns success' do
          result = service.execute

          expect(result[:status]).to eq(:success)
        end
      end

      context 'when mirror_overwrites_diverged_branches is false' do
        let(:error_message) { "Fetching remote upstream failed" }

        before do
          project.mirror_overwrites_diverged_branches = false
        end

        it 'updates the tag' do
          result = service.execute

          expect(result[:status]).to eq(:success)
          expect(project.repository.find_tag('v1.0.0').dereferenced_target.id).to eq(mirror_modified_tag_sha)
        end

        it 'does not update the modified branch' do
          service.execute

          expect(project.repository.find_branch('feature').dereferenced_target.id).not_to eq(mirror_modified_branch_sha)
        end

        it 'returns success' do
          result = service.execute

          expect(result[:status]).to eq(:success)
        end
      end
    end

    context 'updating branches' do
      context 'when the mirror has a repository' do
        let(:master) { "master" }

        before do
          stub_fetch_mirror(project)
        end

        it 'creates new branches' do
          service.execute

          expect(project.repository.branch_names).to include("new-branch")
        end

        it 'does not execute N+1 redis cache commands' do
          modify_branch(project.repository, 'branch-1', remote: true)
          modify_branch(project.repository, 'branch-2', remote: true)

          control = RedisCommands::Recorder.new(pattern: ':branch_names:') { service.execute }

          expect(control).not_to exceed_redis_command_calls_limit(:sadd, 1)
        end

        it 'updates existing branches' do
          service.execute

          expect(project.repository.find_branch("existing-branch").dereferenced_target)
            .to eq(project.repository.find_branch(master).dereferenced_target)
        end

        context 'when branch cannot be created' do
          before do
            modify_branch(project.repository, 'HEAD', remote: true)
          end

          it 'returns an error' do
            result = service.execute

            expect(result).to eq(status: :error, message: 'Branch name is invalid')
          end
        end

        context 'when mirror only protected branches option is set' do
          let(:new_protected_branch_name) { "new-branch" }
          let(:protected_branch_name) { "existing-branch" }

          before do
            project.update!(only_mirror_protected_branches: true)
          end

          it 'creates a new protected branch' do
            create(:protected_branch, project: project, name: new_protected_branch_name)
            project.reload

            service.execute

            expect(project.repository.branch_names).to include(new_protected_branch_name)
          end

          it 'does not create an unprotected branch' do
            service.execute

            expect(project.repository.branch_names).not_to include(new_protected_branch_name)
          end

          it 'updates existing protected branches' do
            create(:protected_branch, project: project, name: protected_branch_name)
            project.reload

            service.execute

            expect(project.repository.find_branch(protected_branch_name).dereferenced_target)
              .to eq(project.repository.find_branch(master).dereferenced_target)
          end

          it 'does not update unprotected branches' do
            service.execute

            expect(project.repository.find_branch(protected_branch_name).dereferenced_target)
              .not_to eq(project.repository.find_branch(master).dereferenced_target)
          end
        end

        context 'when mirror_branch_regex is set' do
          let(:new_branch_name) { "new-branch" }
          let(:existing_branch_name) { "existing-branch" }
          let(:fake_regex) { instance_spy(Gitlab::UntrustedRegexp) }
          let!(:project_setting) { create(:project_setting, project: project, mirror_branch_regex: 'fake_regex') }

          before do
            allow(Gitlab::UntrustedRegexp).to receive(:new)
                                    .with('fake_regex')
                                    .and_return(fake_regex)

            allow(fake_regex).to receive(:match?).and_return(false)
          end

          it 'create a new matched branch' do
            allow(fake_regex).to receive(:match?).with(new_branch_name).and_return(true)
            service.execute
            expect(project.repository.branch_names).to include(new_branch_name)
          end

          it 'does not create mismatched branch' do
            service.execute
            expect(project.repository.branch_names).not_to include(new_branch_name)
          end

          it 'updates existing matched branches' do
            allow(fake_regex).to receive(:match?).with('existing-branch').and_return(true)
            service.execute

            expect(project.repository.find_branch(existing_branch_name).dereferenced_target)
              .to eq(project.repository.find_branch(master).dereferenced_target)
          end

          it 'does not update mismatched branches' do
            service.execute

            expect(project.repository.find_branch(existing_branch_name).dereferenced_target)
              .not_to eq(project.repository.find_branch(master).dereferenced_target)
          end
        end

        context 'with diverged branches' do
          let(:diverged_branch) { "markdown" }

          context 'when mirror_overwrites_diverged_branches is true' do
            it 'update diverged branches' do
              project.mirror_overwrites_diverged_branches = true

              service.execute

              expect(project.repository.find_branch(diverged_branch).dereferenced_target)
                .to eq(project.repository.find_branch(master).dereferenced_target)
            end
          end

          context 'when mirror_overwrites_diverged_branches is false' do
            it "doesn't update diverged branches" do
              project.mirror_overwrites_diverged_branches = false

              service.execute

              expect(project.repository.find_branch(diverged_branch).dereferenced_target)
                .not_to eq(project.repository.find_branch(master).dereferenced_target)
            end
          end

          context 'when mirror_overwrites_diverged_branches is nil' do
            it "doesn't update diverged branches" do
              project.mirror_overwrites_diverged_branches = nil

              service.execute

              expect(project.repository.find_branch(diverged_branch).dereferenced_target)
                .not_to eq(project.repository.find_branch(master).dereferenced_target)
            end
          end
        end
      end

      context 'when project is empty' do
        it 'does not add a default master branch' do
          project    = create(:project_empty_repo, :mirror, import_url: Project::UNKNOWN_IMPORT_URL)
          repository = project.repository

          allow(project).to receive(:fetch_mirror) { create_file(repository) }
          expect(::Branches::CreateService).not_to receive(:create_master_branch)

          service.execute

          expect(repository.branch_names).not_to include('master')
        end
      end

      def create_file(repository)
        repository.create_file(
          project.first_owner,
          '/newfile.txt',
          'hello',
          message: 'Add newfile.txt',
          branch_name: 'newbranch'
        )
      end
    end

    context 'updating LFS objects' do
      context 'when repository does not change' do
        before do
          allow(project).to receive(:lfs_enabled?).and_return(true)
        end

        it 'does not attempt to update LFS objects' do
          expect(Projects::LfsPointers::LfsImportService).not_to receive(:new)

          service.execute
        end
      end

      context 'when repository changes' do
        before do
          stub_fetch_mirror(project)
        end

        context 'when Lfs is disabled in the project' do
          it 'does not update LFS objects' do
            allow(project).to receive(:lfs_enabled?).and_return(false)
            expect(Projects::LfsPointers::LfsObjectDownloadListService).not_to receive(:new)

            service.execute
          end
        end

        context 'when Lfs is enabled in the project' do
          before do
            allow(project).to receive(:lfs_enabled?).and_return(true)
          end

          it 'updates LFS objects' do
            expect(Projects::LfsPointers::LfsImportService).to receive(:new).and_call_original
            expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |instance|
              expect(instance).to receive(:each_list_item)
            end

            service.execute
          end

          context 'when Lfs import fails' do
            let(:error_message) { 'error_message' }

            before do
              expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |instance|
                expect(instance).to receive(:execute).and_return(status: :error, message: error_message)
              end
            end

            # Uncomment once https://gitlab.com/gitlab-org/gitlab-foss/issues/61834 is closed
            # it 'fails mirror operation' do
            #   expect_any_instance_of(Projects::LfsPointers::LfsImportService).to receive(:execute).and_return(status: :error, message: 'error message')

            #   result = subject.execute

            #   expect(result[:status]).to eq :error
            #   expect(result[:message]).to eq 'error message'
            # end

            # Remove once https://gitlab.com/gitlab-org/gitlab-foss/issues/61834 is closed
            it 'does not fail mirror operation' do
              result = subject.execute

              expect(result[:status]).to eq :success
            end

            it 'logs the error' do
              expect_next_instance_of(Gitlab::UpdateMirrorServiceJsonLogger) do |instance|
                expect(instance).to receive(:error).with(hash_including(error_message: error_message))
              end

              subject.execute
            end
          end
        end
      end
    end

    it "fails when the mirror user doesn't have access" do
      stub_fetch_mirror(project)

      result = described_class.new(project, create(:user)).execute

      expect(result[:status]).to eq(:error)
    end

    it "fails when no user is present" do
      result = described_class.new(project, nil).execute

      expect(result[:status]).to eq(:error)
    end

    it "returns success when there is no mirror" do
      project = build_stubbed(:project)
      user    = create(:user)

      result = described_class.new(project, user).execute

      expect(result[:status]).to eq(:success)
    end
  end

  def stub_fetch_mirror(project, repository: project.repository, tags_changed: true )
    allow(project).to receive(:fetch_mirror) { fetch_mirror(repository, tags_changed: tags_changed) }
  end

  def fetch_mirror(repository, tags_changed: true)
    masterrev = repository.find_branch("master").dereferenced_target.id

    parentrev = repository.commit(masterrev).parent_id
    repository.write_ref("refs/heads/existing-branch", parentrev)

    repository.expire_branches_cache
    repository.branches

    # New branch
    repository.write_ref('refs/remotes/upstream/new-branch', masterrev)

    # Updated existing branch
    repository.write_ref('refs/remotes/upstream/existing-branch', masterrev)

    # Diverged branch
    repository.write_ref('refs/remotes/upstream/markdown', masterrev)

    # New tag
    repository.write_ref('refs/tags/new-tag', masterrev)

    # Protected tag
    repository.write_ref('refs/tags/protected-tag', masterrev)

    # New tag that point to a blob
    repository.write_ref('refs/tags/new-tag-on-blob', 'c74175afd117781cbc983664339a0f599b5bb34e')

    Gitaly::FetchRemoteResponse.new(tags_changed: tags_changed)
  end

  def modify_tag(repository, tag_name)
    masterrev = repository.find_branch('master').dereferenced_target.id

    # Modify tag
    repository.write_ref("refs/tags/#{tag_name}", masterrev)
    repository.find_tag(tag_name).dereferenced_target.id
  end

  def modify_branch(repository, branch_name, remote: false)
    masterrev = repository.find_branch('master').dereferenced_target.id

    # Modify branch
    if remote
      repository.write_ref("refs/remotes/upstream/#{branch_name}", masterrev)
    else
      repository.write_ref("refs/heads/#{branch_name}", masterrev)
      repository.find_branch(branch_name).dereferenced_target.id
    end
  end
end
