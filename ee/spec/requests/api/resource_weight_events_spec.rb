# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::ResourceWeightEvents, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: user.namespace) }
  let_it_be(:issue) { create(:issue, project: project, author: user) }

  before do
    project.add_developer(user)
  end

  describe "GET /projects/:id/issues/:noteable_id/resource_weight_events" do
    let!(:event) { create_event }

    it "returns an array of resource weight events" do
      get api("/projects/#{project.id}/issues/#{issue.iid}/resource_weight_events", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['id']).to eq(event.id)
    end

    it "returns a 404 error when issue id not found" do
      get api("/projects/#{project.id}/issues/#{non_existing_record_id}/resource_weight_events", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 when not authorized" do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      private_user = create(:user)

      get api("/projects/#{project.id}/issues/#{issue.iid}/resource_weight_events", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "GET /projects/:id/issues/:noteable_id/resource_weight_events/:event_id" do
    let!(:event) { create_event }

    it "returns a resource weight event by id" do
      get api("/projects/#{project.id}/issues/#{issue.iid}/resource_weight_events/#{event.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(event.id)
    end

    it "returns 404 when not authorized" do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      private_user = create(:user)

      get api("/projects/#{project.id}/issues/#{issue.iid}/resource_weight_events/#{event.id}", private_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 404 error if resource weight event not found" do
      get api("/projects/#{project.id}/issues/#{issue.iid}/resource_weight_events/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'pagination' do
    let!(:event1) { create_event }
    let!(:event2) { create_event }

    # https://gitlab.com/gitlab-org/gitlab/-/issues/220192
    it "returns the second page" do
      get api("/projects/#{project.id}/issues/#{issue.iid}/resource_weight_events?page=2&per_page=1", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.count).to eq(1)
      expect(json_response.first['id']).to eq(event2.id)
    end
  end

  def create_event
    create(:resource_weight_event, issue: issue, weight: 2)
  end
end
