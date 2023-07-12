# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::FoundWikiPage, feature_category: :global_search do
  describe '.initialize' do
    subject { found_wiki_page.wiki }

    let(:wiki_blob) { Gitlab::Search::FoundBlob.new(wiki_blob_params) }
    let(:found_wiki_page) { described_class.new(wiki_blob) }
    let(:wiki_blob_base_params) do
      { path: 'test', basename: 'test', ref: 'master', data: "foo", startline: 2 }
    end

    context 'when found_blob is not a group_level_blob' do
      let_it_be(:project) { create :project, :wiki_repo }
      let(:wiki_blob_params) { wiki_blob_base_params.merge(project: project, project_id: project.id) }

      it { is_expected.to be_an_instance_of(ProjectWiki) }
    end

    context 'when found_blob is a group_level_blob' do
      let_it_be(:group) { create(:group, :wiki_repo) }
      let(:wiki_blob_params) { wiki_blob_base_params.merge(group: group, group_id: group.id, group_level_blob: true) }

      it { is_expected.to be_an_instance_of(GroupWiki) }
    end
  end
end
