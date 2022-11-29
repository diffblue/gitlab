# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GoProxy, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, creator: user, path: 'my-go-lib', group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:version) { 'v1.0.1' }

  let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
  let(:module_name) { "#{Settings.build_gitlab_go_url}/#{project.full_path}" }
  let(:resource) { "#{version}.mod" }

  before :all do
    project.add_developer(user)
    group.add_owner(user)

    create(:go_module_commit, :module, project: project, tag: version)
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.mod' do
    let(:url) { "/projects/#{project.id}/packages/go/#{module_name}/@v/#{resource}" }

    subject { get api(url, user), headers: headers }

    it_behaves_like 'applying ip restriction for group'
  end
end
