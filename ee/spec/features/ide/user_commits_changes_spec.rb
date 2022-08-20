# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE IDE user commits changes', :js do
  include WebIdeSpecHelpers
  include NamespaceStorageHelpers

  before do
    stub_feature_flags(vscode_web_ide: false)
  end

  context 'code owners' do
    let(:project) { create(:project, :custom_repo, files: { 'docs/CODEOWNERS' => "[Backend]\n*.rb @ruby-owner" }) }
    let(:ruby_owner) { create(:user, username: 'ruby-owner') }
    let(:user) { project.first_owner }

    before do
      stub_licensed_features(code_owners: true, code_owner_approval_required: true)

      project.add_developer(ruby_owner)

      create(:protected_branch,
        name: 'master',
        code_owner_approval_required: true,
        project: project)

      sign_in(user)

      ide_visit(project)
    end

    it 'does not show an error message' do
      ide_create_new_file('test.rb', content: '# A ruby file')

      ide_commit

      expect(page).not_to have_content('CODEOWNERS rule violation')
    end
  end

  context 'when namespace storage limits have been exceeded', :saas do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, :repository, group: group) }
    let(:expected_message) do
      "Your push to this repository has been rejected because " \
      "the namespace storage limit of 10 MB has been reached. " \
      "Reduce your namespace storage or purchase additional storage."
    end

    before do
      create(:gitlab_subscription, :ultimate, namespace: group)
      create(:namespace_root_storage_statistics, namespace: group)
      group.add_owner(user)

      enforce_namespace_storage_limit(group)
      set_storage_size_limit(group, megabytes: 10)
      set_used_storage(group, megabytes: 14)

      sign_in(user)
    end

    it 'rejects the commit' do
      ide_visit(project)

      ide_create_new_file('test.txt', content: 'A new file')

      ide_commit

      expect(page).to have_content(expected_message)
    end
  end
end
