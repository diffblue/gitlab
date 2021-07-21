# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repository do
  include RepoHelpers
  include ::EE::GeoHelpers
  include GitHelpers

  before do
    stub_const('TestBlob', Struct.new(:path))
  end

  let_it_be(:primary_node)   { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  def create_remote_branch(remote_name, branch_name, target)
    rugged = rugged_repo(repository)
    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", target.id)
  end

  describe 'delegated methods' do
    subject { repository }

    it { is_expected.to delegate_method(:checksum).to(:raw_repository) }
    it { is_expected.to delegate_method(:find_remote_root_ref).to(:raw_repository) }
  end

  describe '#after_sync' do
    it 'expires repository cache' do
      expect(repository).to receive(:expire_all_method_caches)
      expect(repository).to receive(:expire_branch_cache)
      expect(repository).to receive(:expire_content_cache)

      repository.after_sync
    end

    it 'does not call expire_branch_cache if repository does not exist' do
      allow(repository).to receive(:exists?).and_return(false)

      expect(repository).to receive(:expire_all_method_caches)
      expect(repository).not_to receive(:expire_branch_cache)
      expect(repository).to receive(:expire_content_cache)

      repository.after_sync
    end
  end

  describe '#fetch_upstream' do
    let(:url) { "http://example.com" }

    it 'fetches the URL without creating a remote' do
      expect(repository).not_to receive(:add_remote)
      expect(repository)
        .to receive(:fetch_remote)
        .with(described_class::MIRROR_REMOTE, url: url, refmap: ['+refs/heads/*:refs/remotes/upstream/*'], ssh_auth: nil, forced: true, check_tags_changed: true)
        .and_return(nil)

      repository.fetch_upstream(url, forced: true, check_tags_changed: true)
    end
  end

  describe '#with_config' do
    let(:rugged) { rugged_repo(repository) }
    let(:entries) do
      {
        'test.foo1' => 'hello',
        'test.foo2' => 'world',
        'http.http://gitlab-primary.geo/gitlab-qa-sandbox-group/qa-test-10-07-2018-07-22-41/geo-project-ac55ec2cd134afea.wiki.git.extraHeader' => 'Authorization: blabla'
      }
    end

    it 'sets config only during the block' do
      keys_should_not_be_set

      repository.with_config(entries) do
        entries.each do |key, value|
          expect(rugged.config[key]).to eq(value)
        end
      end

      keys_should_not_be_set
    end

    def keys_should_not_be_set
      entries.each do |key, value|
        expect(rugged.config[key]).to be_blank
      end
    end
  end

  describe "Elastic search", :elastic do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    describe "class method find_commits_by_message_with_elastic" do
      it "returns commits", :sidekiq_might_not_need_inline do
        project = create :project, :repository
        project1 = create :project, :repository

        project.repository.index_commits_and_blobs
        project1.repository.index_commits_and_blobs

        ensure_elasticsearch_index!

        expect(described_class.find_commits_by_message_with_elastic('initial').first).to be_a(Commit)
        expect(described_class.find_commits_by_message_with_elastic('initial').count).to eq(2)
        expect(described_class.find_commits_by_message_with_elastic('initial').total_count).to eq(2)
      end
    end

    describe "find_commits_by_message_with_elastic" do
      it "returns commits", :sidekiq_might_not_need_inline do
        project = create :project, :repository

        project.repository.index_commits_and_blobs
        ensure_elasticsearch_index!

        expect(project.repository.find_commits_by_message_with_elastic('initial').first).to be_a(Commit)
        expect(project.repository.find_commits_by_message_with_elastic('initial').count).to eq(1)
        expect(project.repository.find_commits_by_message_with_elastic('initial').total_count).to eq(1)
      end
    end
  end

  describe '#upstream_branches' do
    it 'returns branches from the upstream remote' do
      masterrev = repository.find_branch('master').dereferenced_target
      create_remote_branch('upstream', 'upstream_branch', masterrev)

      expect(repository.upstream_branches.size).to eq(1)
      expect(repository.upstream_branches.first).to be_an_instance_of(Gitlab::Git::Branch)
      expect(repository.upstream_branches.first.name).to eq('upstream_branch')
    end
  end

  describe '#keep_around' do
    let(:sha) { sample_commit.id }

    context 'on a Geo primary' do
      before do
        stub_current_geo_node(primary_node)
      end

      context 'when a single SHA is passed' do
        it 'creates a RepositoryUpdatedEvent' do
          expect do
            repository.keep_around(sha)
          end.to change { ::Geo::RepositoryUpdatedEvent.count }.by(1)
        end
      end

      context 'when multiple SHAs are passed' do
        it 'creates exactly one RepositoryUpdatedEvent' do
          expect do
            repository.keep_around(sha, sample_big_commit.id)
          end.to change { ::Geo::RepositoryUpdatedEvent.count }.by(1)
        end
      end
    end

    context 'on a Geo secondary' do
      before do
        stub_current_geo_node(secondary_node)
      end

      it 'does not create a RepositoryUpdatedEvent' do
        expect do
          repository.keep_around(sha)
        end.not_to change { ::Geo::RepositoryUpdatedEvent.count }
      end
    end
  end

  describe '#code_owners_blob' do
    it 'returns nil if there is no codeowners file' do
      expect(repository.code_owners_blob(ref: 'master')).to be_nil
    end

    it 'returns the content of the codeowners file when it is found' do
      expect(repository.code_owners_blob(ref: 'with-codeowners').data).to include('example CODEOWNERS file')
    end

    it 'requests the CODOWNER blobs in batch in the correct order' do
      expect(repository).to receive(:blobs_at)
                              .with([%w(master CODEOWNERS),
                                     %w(master docs/CODEOWNERS),
                                     %w(master .gitlab/CODEOWNERS)])
                              .and_call_original

      repository.code_owners_blob(ref: 'master')
    end
  end

  describe '#after_change_head' do
    it 'creates a RepositoryUpdatedEvent on a Geo primary' do
      stub_current_geo_node(primary_node)

      expect { repository.after_change_head }
        .to change { ::Geo::RepositoryUpdatedEvent.count }.by(1)
    end

    it 'does not create a RepositoryUpdatedEvent on a Geo secondary' do
      stub_current_geo_node(secondary_node)

      expect { repository.after_change_head }
        .not_to change { ::Geo::RepositoryUpdatedEvent.count }
    end
  end

  describe "#insights_config_for" do
    context 'when no config file exists' do
      it 'returns nil if does not exist' do
        expect(repository.insights_config_for(repository.root_ref)).to be_nil
      end
    end

    it 'returns nil for an empty repository' do
      allow(repository).to receive(:empty?).and_return(true)

      expect(repository.insights_config_for(repository.root_ref)).to be_nil
    end

    it 'returns a valid Insights config file' do
      project = create(:project, :custom_repo, files: { Gitlab::Insights::CONFIG_FILE_PATH => "monthlyBugsCreated:\n  title: My chart" })

      expect(project.repository.insights_config_for(project.repository.root_ref)).to eq("monthlyBugsCreated:\n  title: My chart")
    end
  end

  describe '#lfs_enabled?' do
    subject { repository.lfs_enabled? }

    context 'for a group wiki repository' do
      let(:repository) { build_stubbed(:group_wiki).repository }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end
  end

  describe '#update_root_ref' do
    let(:url) { 'http://git.example.com/remote-repo.git' }
    let(:auth) { 'Basic secret' }

    it 'updates the default branch when HEAD has changed' do
      stub_find_remote_root_ref(repository, ref: 'feature')

      expect { repository.update_root_ref('origin', url, auth) }
        .to change { project.default_branch }
        .from('master')
        .to('feature')
    end

    it 'always updates the default branch even when HEAD does not change' do
      stub_find_remote_root_ref(repository, ref: 'master')

      expect(repository).to receive(:change_head).with('master').and_call_original

      repository.update_root_ref('origin', url, auth)

      expect(project.default_branch).to eq('master')
    end

    it 'does not update the default branch when HEAD does not exist' do
      stub_find_remote_root_ref(repository, ref: 'foo')

      expect { repository.update_root_ref('origin', url, auth) }
        .not_to change { project.default_branch }
    end

    it 'does not raise error when repository does not exist' do
      allow(repository).to receive(:find_remote_root_ref)
        .with('origin', url, auth)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      expect { repository.update_root_ref('origin', url, auth) }.not_to raise_error
    end

    def stub_find_remote_root_ref(repository, ref:)
      allow(repository)
        .to receive(:find_remote_root_ref)
        .with('origin', url, auth)
        .and_return(ref)
    end
  end
end
