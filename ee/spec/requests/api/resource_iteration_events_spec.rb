# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ResourceIterationEvents, feature_category: :team_planning do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }
  let!(:project) { create(:project, :public, namespace: group) }
  let!(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }

  before do
    project.add_developer(user)
  end

  RSpec.shared_examples 'resource_iteration_events API' do |parent_type, eventable_type, id_name|
    describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_iteration_events" do
      let!(:event) { create_event(iteration) }

      it 'returns an array of resource iteration events' do
        url = "/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_iteration_events"
        get api(url, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(event.id)
        expect(json_response.first['resource_id']).to eq(eventable.id)
        expect(json_response.first['iteration']['id']).to eq(event.iteration.id)
        expect(json_response.first['action']).to eq(event.action)
      end

      it 'returns a 404 error when eventable id not found' do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{non_existing_record_id}/resource_iteration_events", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 404 when not authorized' do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        non_member = create(:user)

        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_iteration_events", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_iteration_events/:event_id" do
      let!(:event) { create_event(iteration) }

      it 'returns a resource iteration event by id' do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_iteration_events/#{event.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(event.id)
        expect(json_response['iteration']['id']).to eq(event.iteration.id)
        expect(json_response['action']).to eq(event.action)
      end

      it 'returns 404 when not authorized' do
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        non_member = create(:user)

        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_iteration_events/#{event.id}", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 error if resource iteration event not found' do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_iteration_events/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'pagination' do
      let!(:event1) { create_event(iteration) }
      let!(:event2) { create_event(iteration) }

      it 'returns the second page' do
        get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_iteration_events?page=2&per_page=1", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(1)
        expect(json_response.first['id']).to eq(event2.id)
      end
    end

    def create_event(iteration, action: :add)
      create(:resource_iteration_event, eventable.class.name.underscore => eventable, iteration: iteration, action: action)
    end
  end

  context 'when eventable is an Issue' do
    it_behaves_like 'resource_iteration_events API', 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:eventable) { create(:issue, project: project, author: user) }
    end
  end
end
