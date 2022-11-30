# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ComposerPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:package_name) { 'package-name' }
  let_it_be(:project) do
    create(:project, :custom_repo, files: { 'composer.json' => Gitlab::Json.dump({ name: package_name }) },
                                   group: group)
  end

  let_it_be(:package) { create(:composer_package, :with_metadatum, name: package_name, project: project) }

  let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
  let(:params) { {} }

  subject { get api(url), headers: headers, params: params }

  before do
    group.add_maintainer(user)
  end

  describe 'GET /api/v4/projects/:id/packages/composer/archives/*package_name?sha=:sha' do
    let(:url) { "/projects/#{project.id}/packages/composer/archives/#{package_name}.zip" }
    let(:params) { { sha: project.repository.find_branch('master').target } }

    it_behaves_like 'applying ip restriction for group'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/p2/*package_name.json' do
    let(:url) { "/group/#{group.id}/-/packages/composer/p2/#{package_name}.json" }

    it_behaves_like 'applying ip restriction for group'
  end
end
