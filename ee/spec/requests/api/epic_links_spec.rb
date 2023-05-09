# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::EpicLinks, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:ancestor) { create(:group) }
  let_it_be(:group, reload: true) { create(:group, parent: ancestor) }
  let_it_be(:epic) { create(:epic, group: group) }
  let(:features_when_forbidden) { { epics: true, subepics: false } }
  let(:group_path) { "#{ancestor.path}%2F#{group.path}" }

  shared_examples 'user does not have access' do
    it 'returns 403 when subepics feature is disabled' do
      stub_licensed_features(features_when_forbidden)

      group.add_developer(user)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'unauthenticated user' do
      let(:user) { nil }

      it 'returns 401 unauthorized error' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it 'returns 404 not found error for a user without permissions to see the group' do
      group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /groups/:id/epics/:epic_iid/epics' do
    let(:url) { "/groups/#{group_path}/epics/#{epic.iid}/epics" }
    let(:features_when_forbidden) { { epics: false } }

    subject { get api(url, user) }

    it_behaves_like 'user does not have access'

    context 'when subepics feature is enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      let_it_be(:child_epic1) { create(:epic, group: group, parent: epic, relative_position: 200) }
      let_it_be(:child_epic2) { create(:epic, group: group, parent: epic, relative_position: 100) }

      it 'returns 200 status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
        expect(json_response.map { |epic| epic["id"] }).to contain_exactly(child_epic2.id, child_epic1.id)
      end

      context 'with group hierarchy' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:other_child) { create(:epic, group: other_group, parent: epic) }
        let_it_be(:ancestor_child) { create(:epic, group: ancestor, parent: epic) }
        let_it_be(:subgroup_child) { create(:epic, group: subgroup, parent: epic) }

        before do
          ancestor.add_reporter(user)
          other_group.add_reporter(user)
          subgroup.add_reporter(user)
        end

        it 'returns children from any group hierarchy' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
          expect(json_response.map { |epic| epic["id"] }).to contain_exactly(
            child_epic2.id,
            child_epic1.id,
            other_child.id,
            ancestor_child.id,
            subgroup_child.id
          )
        end

        it 'executes limited number of N+1 queries', :use_sql_query_cache do
          def get_epics
            get api(url, user)
          end

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get_epics }

          create_list(:epic, 2, parent: epic)

          # Executes 2 extra `SELECT COUNT(*) FROM "award_emoji"...` per child
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/382164
          expect { get_epics }.not_to exceed_all_query_limit(control).with_threshold(4)
        end
      end
    end
  end

  describe 'POST /groups/:id/epics/:epic_iid/epics/child_epic_id' do
    let_it_be(:child_epic) { create(:epic, group: group) }
    let(:url) { "/groups/#{group_path}/epics/#{epic.iid}/epics/#{child_epic.id}" }

    subject { post api(url, user) }

    it_behaves_like 'user does not have access'

    context 'when subepics feature is enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when user is not a member' do
        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when user is guest' do
        it 'returns 201 status' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
          expect(epic.reload.children).to include(child_epic)
        end
      end

      context 'when target epic cannot be read' do
        let_it_be(:other_group) { create(:group, :private) }
        let_it_be(:child_epic) { create(:epic, group: other_group) }

        it 'returns 404 status' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /groups/:id/epics/:epic_iid/epics' do
    let(:url) { "/groups/#{group_path}/-/epics/#{epic.iid}/epics" }

    subject { post api(url, user), params: { title: 'child epic' } }

    it_behaves_like 'user does not have access'

    context 'when subepics feature is enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when user is not a member' do
        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when user is a guest' do
        before do
          group.add_guest(user)
        end

        it 'returns 201 status' do
          subject

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/linked_epic', dir: 'ee')
          expect(epic.reload.children).to include(Epic.last)
        end
      end

      context 'when user is a reporter' do
        before do
          group.add_reporter(user)
        end

        it 'returns 201 status' do
          subject

          child_epic = Epic.last
          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/linked_epic', dir: 'ee')
          expect(epic.reload.children).to include(child_epic)
          expect(epic.notes.last&.note).to eq("added epic #{child_epic.to_reference} as child epic")
          expect(child_epic.notes.last&.note).to eq("added epic #{epic.to_reference} as parent epic")
        end

        context 'when the parent epic is confidential' do
          let_it_be(:epic) { create(:epic, group: group, confidential: true) }

          it 'copies the confidentiality status from the parent epic' do
            subject

            expect(Epic.last).to be_confidential
          end

          it 'does not allow creating a non-confidential sub-epic' do
            post api(url, user), params: { title: 'child epic', confidential: false }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        it 'does apply the confidential parameter if set' do
          post api(url, user), params: { title: 'child epic', confidential: true }

          expect(Epic.last).to be_confidential
        end

        context 'and epic has errors' do
          it 'returns 400 error' do
            child_epic = Epic.new(title: 'with errors')
            errors = ActiveModel::Errors.new(child_epic).tap { |e| e.add(:parent_id, "error message") }
            allow(child_epic).to receive(:errors).and_return(errors)
            allow_next_instance_of(Epics::CreateService) do |service|
              allow(service).to receive(:execute).and_return(child_epic)
            end

            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end
  end

  describe 'PUT /groups/:id/epics/:epic_iid/epics/:child_epic_id' do
    let_it_be(:child_epic) { create(:epic, group: group, parent: epic, relative_position: 100) }
    let_it_be(:sibling_1) { create(:epic, group: group, parent: epic, relative_position: 200) }
    let_it_be(:sibling_2) { create(:epic, group: group, parent: epic, relative_position: 300) }

    let(:url) { "/groups/#{group_path}/epics/#{epic.iid}/epics/#{child_epic.id}" }

    subject { put api(url, user), params: { move_before_id: sibling_1.id, move_after_id: sibling_2.id } }

    it_behaves_like 'user does not have access'

    context 'when subepics are enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when user has permissions to reorder epics' do
        before do
          group.add_guest(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
          expect(json_response.map { |epic| epic['id'] }).to eq([sibling_1.id, child_epic.id, sibling_2.id])
        end

        context 'when child belongs to a different group hierarchy' do
          let_it_be(:other_child) { create(:epic, group: other_group, parent: epic, relative_position: 100) }
          let(:url) { "/groups/#{group_path}/epics/#{epic.iid}/epics/#{other_child.id}" }

          it 'returns status 404 if user is not a member' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end

          it 'returns status 200 if user has guest access' do
            other_group.add_guest(user)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
            expect(json_response.map { |epic| epic['id'] }).to contain_exactly(
              child_epic.id,
              sibling_1.id,
              other_child.id,
              sibling_2.id
            )
          end
        end
      end

      context 'when user does not have permissions to reorder epics' do
        it 'returns status 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /groups/:id/epics/:epic_iid/epics' do
    let_it_be(:child_epic) { create(:epic, group: group, parent: epic) }
    let(:url) { "/groups/#{group_path}/epics/#{epic.iid}/epics/#{child_epic.id}" }
    let(:features_when_forbidden) { { epics: false } }

    subject { delete api(url, user) }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user is not a member' do
        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when user is guest' do
        it 'returns 200 status' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
          expect(epic.reload.children).not_to include(child_epic)
        end

        context 'with confidential epic' do
          let_it_be(:epic) { create(:epic, group: group, confidential: true) }
          let_it_be(:child_epic) { create(:epic, group: group, parent: epic, confidential: true) }

          it 'returns status 403' do
            subject

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      context 'when child belongs to a different group hierarchy' do
        let_it_be(:child_epic) { create(:epic, group: other_group, parent: epic) }

        context "when user is not a member of the child's group" do
          before do
            group.add_guest(user)
          end

          it 'returns 404 status' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context "when user has guest access to child's group" do
          before do
            group.add_guest(user)
            other_group.add_guest(user)
          end

          it 'returns 200 status' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
            expect(epic.reload.children).not_to include(child_epic)
          end
        end
      end
    end

    context 'when epics feature is disabled' do
      before do
        stub_licensed_features(epics: false)
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        it 'returns 403 status' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end
end
