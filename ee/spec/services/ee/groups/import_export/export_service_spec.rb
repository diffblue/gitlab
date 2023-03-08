# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ImportExport::ExportService, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) do
    create(:group).tap do |g|
      g.add_owner(user)
    end
  end

  let_it_be(:group_wiki) do
    create(:group_wiki, group: group).tap do |wiki|
      wiki.create_page('test', 'test_content')
    end
  end

  let(:shared) { Gitlab::ImportExport::Shared.new(group) }
  let(:archive_path) { shared.archive_path }

  subject(:export_service) { described_class.new(group: group, user: user, params: { shared: shared }) }

  after do
    FileUtils.rm_rf(archive_path)
  end

  describe '#execute' do
    it 'exports group and descendants wiki repositories' do
      subgroup = create(:group, :wiki_repo, parent: group)
      subgroup.wiki.create_page('test', 'test_content')

      expect_next_instance_of(::Gitlab::ImportExport::Group::GroupAndDescendantsRepoSaver, group: group, shared: shared) do |exporter|
        expect(exporter).to receive(:save).and_call_original
      end

      # Avoid cleaning the tmp files in order to check the content of the dir
      allow(export_service).to receive(:remove_archive_tmp_dir)

      allow_next_instance_of(Gitlab::ImportExport::Saver) do |saver|
        allow(saver).to receive(:save).and_return(true)
      end

      export_service.execute

      expect(File.exist?(Gitlab::ImportExport.group_wiki_repo_bundle_full_path(shared, group.id))).to eq true
      expect(File.exist?(Gitlab::ImportExport.group_wiki_repo_bundle_full_path(shared, subgroup.id))).to eq true
    end
  end
end
