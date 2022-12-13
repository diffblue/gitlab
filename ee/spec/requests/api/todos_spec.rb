# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Todos, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group) }

  describe 'GET /todos' do
    let(:author_1) { create(:user) }
    let!(:pat) { create(:personal_access_token, user: user) }

    before do
      group.add_developer(user)
      group.add_developer(author_1)
    end

    def create_todo_for_new_epic
      new_group = create(:group)
      label = create(:label)
      new_epic = create(:labeled_epic, group: new_group, labels: [label])
      new_group.add_developer(author_1)
      new_group.add_developer(user)
      create(:todo, project: nil, group: new_group, author: author_1, user: user, target: new_epic)
    end

    context 'when there is an Epic Todo' do
      let!(:epic_todo) { create_todo_for_new_epic }

      before do
        stub_licensed_features(epics: true)

        get api('/todos', personal_access_token: pat)
      end

      specify do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'avoids N+1 queries', :request_store do
        create_todo_for_new_epic

        control = ActiveRecord::QueryRecorder.new { get api('/todos', personal_access_token: pat) }

        create_todo_for_new_epic

        # Additional query due to authorization check on new group
        expect { get api('/todos', personal_access_token: pat) }.not_to exceed_query_limit(control).with_threshold(1)
      end

      it 'includes the Epic Todo in the response' do
        expect(json_response).to include(
          a_hash_including('id' => epic_todo.id)
        )
      end
    end
  end

  describe 'POST :id/epics/:epic_iid/todo' do
    subject { post api("/groups/#{group.id}/epics/#{epic.iid}/todo", user) }

    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'creates a todo on an epic' do
        expect { subject }.to change { Todo.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['project']).to be_nil
        expect(json_response['group']).to be_a(Hash)
        expect(json_response['author']).to be_a(Hash)
        expect(json_response['target_type']).to eq('Epic')
        expect(json_response['target']).to be_a(Hash)
        expect(json_response['target_url']).to be_present
        expect(json_response['body']).to be_present
        expect(json_response['state']).to eq('pending')
        expect(json_response['action_name']).to eq('marked')
        expect(json_response['created_at']).to be_present
      end

      it 'returns 304 there already exist a todo on that epic' do
        stub_feature_flags(multiple_todos: false)

        create(:todo, project: nil, group: group, user: user, target: epic)

        subject

        expect(response).to have_gitlab_http_status(:not_modified)
      end

      it 'returns 404 if the epic is not found' do
        group.add_developer(user)

        post api("/groups/#{group.id}/epics/#{non_existing_record_iid}/todo", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns an error if the epic is not accessible' do
        group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
