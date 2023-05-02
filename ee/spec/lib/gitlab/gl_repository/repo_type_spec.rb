# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GlRepository::RepoType do
  describe Gitlab::GlRepository::WIKI do
    context 'group wiki' do
      let_it_be(:wiki) { create(:group_wiki) }

      it_behaves_like 'a repo type' do
        let(:expected_id) { wiki.group.id }
        let(:expected_identifier) { "group-#{expected_id}-wiki" }
        let(:expected_suffix) { '.wiki' }
        let(:expected_container) { wiki }
        let(:expected_repository_resolver) { expected_container }
        let(:expected_repository) { ::Repository.new(wiki.full_path, wiki, shard: wiki.repository_storage, disk_path: wiki.disk_path, repo_type: described_class) }
      end

      describe '#identifier_for_container' do
        subject { described_class.identifier_for_container(wiki.group) }

        it { is_expected.to eq("group-#{wiki.group.id}-wiki") }
      end
    end
  end
end
