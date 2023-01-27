# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController, feature_category: :source_code_management do
  context 'when repository container is a group wiki' do
    include WikiHelpers

    let_it_be(:group) { create(:group, :wiki_repo) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { nil }

    before_all do
      group.add_owner(user)
    end

    before do
      stub_group_wikis(true)
    end

    it_behaves_like described_class do
      let(:container) { group.wiki }
      let(:access_checker_class) { Gitlab::GitAccessWiki }
    end
  end

  context 'git audit streaming event' do
    include GitHttpHelpers

    it_behaves_like 'sends git audit streaming event' do
      subject do
        post :git_upload_pack, params: { repository_path: "#{project.full_path}.git" }
      end
    end
  end
end
