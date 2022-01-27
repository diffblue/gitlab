# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequestsController, '(JavaScript fixtures in EE context)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:project) { create(:project, :repository, path: 'merge-requests-project') }
  let(:user) { project.first_owner }
  let(:merge_request) { create(:merge_request, source_project: project) }

  render_views

  before do
    sign_in(user)
  end

  it 'ee/merge_requests/merge_request_with_multiple_assignees_feature.html' do
    stub_licensed_features(multiple_merge_request_assignees: true)

    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param
    }, format: :html

    expect(response).to be_successful
  end
end
