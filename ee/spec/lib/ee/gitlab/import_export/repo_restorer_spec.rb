# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::RepoRestorer do
  describe 'restores group wiki bundles' do
    let(:group) { create(:group) }
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec" }
    let(:bundle_path) { ::Gitlab::ImportExport.group_wiki_repo_bundle_full_path(shared, group_wiki.container.id) }
    let(:bundler) { Gitlab::ImportExport::WikiRepoSaver.new(exportable: group_wiki.container, shared: shared) }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:restorer) do
      described_class.new(path_to_bundle: bundle_path,
                          shared: shared,
                          importable: GroupWiki.new(group))
    end

    before do
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(export_path)
      end

      bundler.save # rubocop:disable Rails/SaveBang
    end

    after do
      FileUtils.rm_rf(export_path)
      gitlab_shell.remove_repository(group_wiki.repository_storage, group_wiki.disk_path)
      gitlab_shell.remove_repository(group.wiki.repository_storage, group.wiki.disk_path)
    end

    context 'when group wiki in bundle' do
      let_it_be(:page_title) { 'index' }
      let_it_be(:page_content) { 'test content' }
      let_it_be(:group_wiki) do
        create(:group_wiki).tap do |group_wiki|
          group_wiki.create_page(page_title, page_content)
        end
      end

      it 'restores the repo successfully', :aggregate_failures do
        expect(group.wiki_repository_exists?).to be false

        expect { restorer.restore }.to change { GroupWikiRepository.count }.by(1)

        group.wiki.repository.expire_status_cache
        expect(group.wiki_repository_exists?).to be true

        pages = group.wiki.list_pages(load_content: true)
        expect(pages.size).to eq 1
        expect(pages.first.title).to eq page_title
        expect(pages.first.content).to eq page_content
      end
    end

    context 'when no group wiki in the bundle', :aggregate_failures do
      let_it_be(:group_wiki) { create(:group_wiki) }

      it 'does not creates an empty wiki' do
        expect(restorer.restore).to be true
        expect(group.wiki_repository_exists?).to be false
        expect(group.group_wiki_repository).to be_nil
      end
    end
  end
end
