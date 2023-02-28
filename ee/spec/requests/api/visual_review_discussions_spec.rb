# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VisualReviewDiscussions, feature_category: :review_apps do
  shared_examples_for 'accepting request without authentication' do
    let(:request) do
      post api("/projects/#{project_id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params
    end

    it_behaves_like 'handling merge request feedback'
  end

  shared_examples_for 'accepting request with authentication' do
    let(:token) { create(:personal_access_token) }
    let(:user) { token.user }

    let(:request) do
      post api("/projects/#{project_id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params, headers: { 'Private-Token' => token.token }
    end

    before do
      create(:project_member,
             user: user,
             project: project,
             access_level: ProjectMember::DEVELOPER)
    end

    it_behaves_like 'handling merge request feedback', :with_auth
  end

  shared_examples_for 'handling merge request feedback' do |with_auth|
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project)
    end

    let(:project_id) { project.id }
    let(:note_params) { { body: 'hi!', created_at: 2.weeks.ago } }
    let(:response_note) { json_response['notes'].first }

    it 'creates a new note' do
      expect { request }.to change(merge_request.notes, :count).by(1)
    end

    it 'tracks a visual review feedback event', :snowplow do
      request

      expect_snowplow_event(
        category: 'Notes::CreateService',
        action: 'execute',
        label: 'anonymous_visual_review_note',
        value: merge_request.notes.last.id
      )
    end

    describe 'the API response' do
      before do
        request
      end

      it 'responds with a status 201 Created' do
        expect(response).to have_gitlab_http_status(:created)
      end

      if with_auth
        it 'returns the persisted note body including user details' do
          expect(response_note['body']).to eq("**Feedback from @#{user.username} (#{user.email})**\n\nhi!")
        end
      else
        it 'returns the persisted note body' do
          expect(response_note['body']).to eq('hi!')
        end
      end

      it 'returns the name of the Visual Review Bot assigned as the author' do
        expect(response_note['author']['username']).to eq(User.visual_review_bot.username)
      end

      it 'returns the id of the merge request as the parent noteable_id' do
        expect(response_note['noteable_id']).to eq(merge_request.id)
      end

      it 'returns a current time stamp instead of the provided one' do
        expect(Time.parse(response_note['created_at']) > 1.day.ago).to eq(true)
      end
    end

    context 'with no message body' do
      let(:note_params) { { some: 'thing' } }

      it 'returns a 400 bad request error if body not given' do
        expect { request }.not_to change(merge_request.notes, :count)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with an invalid project ID' do
      let(:project_id) { project.id + 1 }

      it 'does not create a new note' do
        expect { request }.not_to change(Note, :count)
      end

      describe 'the API response' do
        it 'responds with a status 404' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with an invalid merge request IID' do
      let(:merge_request) { double(iid: 546574823564) }

      it 'does not create a new note' do
        expect { request }.not_to change(Note, :count)
      end

      describe 'the API response' do
        it 'responds with a status 404' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when anonymous_visual_review_feedback feature flag is disabled' do
      before do
        stub_feature_flags(anonymous_visual_review_feedback: false)
      end

      it 'does not create a new note' do
        expect { request }.not_to change(merge_request.notes, :count)
      end

      describe 'the API response' do
        before do
          request
        end

        it 'responds 403' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'returns error messaging specifying that the feature is disabled' do
          expect(json_response['message']).to eq('403 Forbidden - Anonymous visual review feedback is disabled')
        end
      end
    end
  end

  shared_examples_for 'rejecting request without authentication' do
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project)
    end

    let(:project_id) { project.id }
    let(:note_params) { { body: 'hi!', created_at: 2.weeks.ago } }

    let(:request) do
      post api("/projects/#{project_id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params
    end

    it 'returns a 404 project not found' do
      expect { request }.not_to change(merge_request.notes, :count)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when project is public' do
    let!(:project) { create(:project, :public, :repository) }

    it_behaves_like 'accepting request without authentication'
    it_behaves_like 'accepting request with authentication'
  end

  context 'when merge request discussion is locked and project is public' do
    let_it_be(:project) { create(:project, :public, :repository) }
    let(:project_id) { project.id }
    let(:note_params) { { body: 'hi!', created_at: 2.weeks.ago } }
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project, discussion_locked: true)
    end

    let(:request) do
      post api("/projects/#{project_id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params, headers: headers
    end

    context 'without authentication' do
      let(:headers) { {} }

      it 'rejects note creation' do
        expect { request }.not_to change(merge_request.notes, :count)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with visual review bot authentication' do
      let(:token) { create(:personal_access_token, user: User.visual_review_bot) }
      let(:headers) { { 'Private-Token' => token.token } }

      it 'rejects note creation' do
        expect { request }.not_to change(merge_request.notes, :count)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'when project is archived' do
    let_it_be(:project) { create(:project, :public, :repository) }
    let(:project_id) { project.id }
    let(:note_params) { { body: 'hi!', created_at: 2.weeks.ago } }
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project)
    end

    let(:request) do
      post api("/projects/#{project_id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params, headers: headers
    end

    before do
      ::Projects::UpdateService.new(project, project.users.first, archived: true).execute
    end

    context 'without authentication' do
      let(:headers) { {} }

      it 'rejects note creation' do
        expect { request }.not_to change(merge_request.notes, :count)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with visual review bot authentication' do
      let(:token) { create(:personal_access_token, user: User.visual_review_bot) }
      let(:headers) { { 'Private-Token' => token.token } }

      it 'rejects note creation' do
        expect { request }.not_to change(merge_request.notes, :count)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'when project is private' do
    let!(:project) { create(:project, :private, :repository) }

    it_behaves_like 'accepting request with authentication'
    it_behaves_like 'rejecting request without authentication'

    context 'and authenticated user has no project access' do
      let!(:merge_request) do
        create(:merge_request_with_diffs, source_project: project, target_project: project)
      end

      let(:token) { create(:personal_access_token) }
      let(:user) { token.user }
      let(:project_id) { project.id }
      let(:note_params) { { body: 'hi!', created_at: 2.weeks.ago } }

      let(:request) do
        post api("/projects/#{project_id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params, headers: { 'Private-Token' => token.token }
      end

      it 'returns a 404 project not found' do
        expect { request }.not_to change(merge_request.notes, :count)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when project is internal' do
    let!(:project) { create(:project, :internal, :repository) }

    it_behaves_like 'accepting request with authentication'
    it_behaves_like 'rejecting request without authentication'

    context 'and authenticated user has no project access' do
      let(:token) { create(:personal_access_token) }
      let(:user) { token.user }

      let(:request) do
        post api("/projects/#{project_id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params, headers: { 'Private-Token' => token.token }
      end

      it_behaves_like 'handling merge request feedback', :with_auth
    end
  end
end
