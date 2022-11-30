# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RubygemPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package_name) { 'package' }
  let_it_be(:version) { '0.0.1' }
  let_it_be(:package) { create(:rubygems_package, project: project, name: package_name, version: version) }
  let_it_be(:file_name) { "#{package_name}-#{version}.gem" }

  let(:headers) { build_auth_headers(personal_access_token.token) }

  before do
    group.add_maintainer(user)
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/gems/:file_name' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/gems/#{file_name}") }

    subject { get(url, headers: headers) }

    it_behaves_like 'applying ip restriction for group'
  end
end
