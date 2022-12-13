# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::EpicIssues, feature_category: :portfolio_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:epic) { create(:epic, group: group) }

  describe 'GET /groups/:id/epics/:epic_iid/issues' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/issues" }

    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        group.add_developer(user)

        get api(url, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when an error occurs' do
        it 'returns 401 unauthorized error for non authenticated user' do
          get api(url)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'returns 404 not found error for a user without permissions to see the group' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the request is correct' do
        let(:issues) { create_list(:issue, 2, project: project) }
        let!(:epic_issue1) { create(:epic_issue, epic: epic, issue: issues[0]) }
        let!(:epic_issue2) { create(:epic_issue, epic: epic, issue: issues[1]) }

        def perform_request(params = {})
          get api(url, user), params: params
        end

        it 'responds 200 and matches the response schema' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/epic_issues', dir: 'ee')
          expect(response.parsed_body.size).to eq(2)
        end

        it 'accepts pagination params' do
          perform_request({ per_page: 1 })

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/epic_issues', dir: 'ee')
          expect(response.parsed_body.size).to eq(1)
        end

        context 'returns multiple issues without performing N + 1' do
          it 'returns multiple issues without performing N + 1' do
            perform_request

            control_count = ActiveRecord::QueryRecorder.new { perform_request }.count

            issue = create(:issue, project: project)
            create(:epic_issue, epic: epic, issue: issue)

            # Existing N + 1 for calculating subscribed? field: https://gitlab.com/gitlab-org/gitlab/-/issues/325898
            expect { perform_request }.not_to exceed_query_limit(control_count + 2)
          end
        end
      end
    end
  end

  describe 'POST /groups/:id/epics/:epic_iid/issues' do
    let(:issue) { create(:issue, project: project) }
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/issues/#{issue.id}" }

    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        group.add_developer(user)

        post api(url, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
        group.add_guest(user)
      end

      context 'when an error occurs' do
        it 'returns 401 unauthorized error for non authenticated user' do
          post api(url)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'returns 404 not found error for a user without permissions to see the group' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          post api(url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'without permissions to admin the issue' do
          before do
            project.add_guest(user)
          end

          it 'returns 403 forbidden error' do
            post api(url, user)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'without permissions to read the epic' do
          let(:epic) { create(:epic, :confidential, group: create(:group, :private)) }

          before do
            project.add_reporter(user)
          end

          it 'returns 403 forbidden error' do
            post api(url, user)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when issue project is not under the epic group' do
          before do
            other_project = create(:project)
            issue.update_attribute(:project, other_project)

            group.add_developer(user)
            other_project.add_developer(user)
          end

          it 'returns an error' do
            post api(url, user)

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response).to eq('message' => 'No matching issue found. Make sure that you are adding a valid issue URL.')
          end
        end
      end

      context 'when the request is correct' do
        before do
          project.add_reporter(user)

          post api(url, user)
        end

        it 'returns 201 status' do
          expect(response).to have_gitlab_http_status(:created)
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic_issue_link', dir: 'ee')
        end

        it 'assigns the issue to the epic' do
          epic_issue = EpicIssue.last

          expect(epic_issue.issue).to eq(issue)
          expect(epic_issue.epic).to eq(epic)
        end
      end
    end
  end

  describe 'DELETE /groups/:id/epics/:epic_iid/issues/:epic_issue_id"' do
    let(:issue) { create(:issue, project: project) }
    let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/issues/#{epic_issue.id}" }

    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        group.add_developer(user)

        post api(url, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when an error occurs' do
        it 'returns 401 unauthorized error for non authenticated user' do
          delete api(url)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'returns 404 not found error for a user without permissions to see the group' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          delete api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'With user without permissions to admin the issue' do
          before do
            project.add_guest(user)
          end

          it 'returns 403 forbidden error' do
            delete api(url, user)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'without permissions to read the epic' do
          before do
            [issue, epic].map { |issuable| issuable.update!(confidential: true) }
            project.add_reporter(user)
          end

          it 'returns 403 forbidden error' do
            delete api(url, user)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when epic_issue association does not include the epic in the url' do
          before do
            other_group = create(:group)
            other_group_epic = create(:epic, group: other_group)
            epic_issue.update_attribute(:epic, other_group_epic)

            group.add_developer(user)
            other_group.add_developer(user)
          end

          it 'returns 404 not found error' do
            delete api(url, user)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when the request is correct' do
        before do
          group.add_developer(user)
        end

        it 'returns 200 status' do
          delete api(url, user)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'matches the response schema' do
          delete api(url, user)

          expect(response).to match_response_schema('public_api/v4/epic_issue_link', dir: 'ee')
        end

        it 'removes the association' do
          expect { delete api(url, user) }.to change { EpicIssue.count }.from(1).to(0)
        end
      end
    end
  end

  describe 'PUT /groups/:id/epics/:epic_iid/issues/:epic_issue_id' do
    let(:issues) { create_list(:issue, 2, project: project) }
    let!(:epic_issue1) { create(:epic_issue, epic: epic, issue: issues[0], relative_position: 1) }
    let!(:epic_issue2) { create(:epic_issue, epic: epic, issue: issues[1], relative_position: 2) }

    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/issues/#{epic_issue1.id}?move_after_id=#{epic_issue2.id}" }

    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        group.add_developer(user)
        put api(url, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when an error occurs' do
        it 'returns 401 unauthorized error for non authenticated user' do
          put api(url)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'returns 404 not found error for a user without permissions to see the group' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          put api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 403 forbidden error for a user who can not move the issue' do
          put api(url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'returns 404 not found error for the link of another epic' do
          group.add_developer(user)
          another_epic = create(:epic, group: group)
          url = "/groups/#{group.path}/epics/#{another_epic.iid}/issues/#{epic_issue1.id}?move_after_id=#{epic_issue2.id}"

          put api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the request is correct' do
        before do
          group.add_developer(user)
          put api(url, user)
        end

        it 'returns 200 status' do
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates the positions values' do
          expect(epic_issue1.reload.relative_position).to be < epic_issue2.relative_position
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic_issues', dir: 'ee')
        end
      end
    end
  end
end
