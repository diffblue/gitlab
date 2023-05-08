# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EpicsController, feature_category: :portfolio_management do
  let(:group) { create(:group, :private) }
  let(:epic) { create(:epic, group: group) }
  let(:user)  { create(:user) }
  let(:label) { create(:group_label, group: group, title: 'Bug') }

  before do
    sign_in(user)
  end

  context 'when epics feature is disabled' do
    shared_examples '404 status' do
      it 'returns 404 status' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'GET #index' do
      subject { get :index, params: { group_id: group } }

      it_behaves_like '404 status'
    end

    describe 'GET #new' do
      subject { get :new, params: { group_id: group } }

      it_behaves_like '404 status'
    end

    describe 'GET #show' do
      subject { get :show, params: { group_id: group, id: epic.to_param } }

      it_behaves_like '404 status'
    end

    describe 'PUT #update' do
      subject { put :update, params: { group_id: group, id: epic.to_param } }

      it_behaves_like '404 status'
    end
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    describe "GET #index" do
      let!(:epic_list) { create_list(:epic, 2, group: group) }

      before do
        sign_in(user)
        group.add_developer(user)
      end

      it "returns index" do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'GET #discussions' do
      before do
        sign_in(user)
        group.add_developer(user)
      end

      context 'when issue note is returned' do
        before do
          SystemNoteService.epic_issue(epic, issue, user, :added)
        end

        shared_examples 'issue link presence' do
          let(:issue) { create(:issue, project: project, description: "Project Issue") }

          it 'the link to the issue is included' do
            get :discussions, params: { group_id: group, id: epic.to_param }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
            discussion = json_response[0]
            notes = discussion["notes"]
            expect(notes.size).to eq(1)
            expect(notes[0]["note_html"]).to include(project_issue_path(project, issue))
          end
        end

        describe 'project default namespace' do
          it_behaves_like 'issue link presence' do
            let(:project) { create(:project, :public) }
          end
        end

        describe 'project group namespace' do
          it_behaves_like 'issue link presence' do
            let(:project) { create(:project, namespace: group) }
          end
        end
      end

      context 'setting notes filter' do
        let(:issuable) { epic }
        let(:issuable_parent) { group }
        let!(:discussion_note) { create(:note, :system, noteable: issuable) }
        let!(:discussion_comment) { create(:note, noteable: issuable) }

        it_behaves_like 'issuable notes filter'
      end
    end

    describe 'GET #new' do
      it 'renders template' do
        group.add_developer(user)
        get :new, params: { group_id: group }

        expect(response).to render_template 'groups/epics/new'
      end

      context 'with unauthorized user' do
        it 'returns a not found 404 response' do
          get :new, params: { group_id: group }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'GET #show' do
      def show_epic(format = :html)
        get :show, params: { group_id: group, id: epic.to_param }, format: format
      end

      context 'when format is HTML' do
        it 'renders template' do
          group.add_developer(user)
          show_epic

          expect(response.media_type).to eq 'text/html'
          expect(response).to render_template 'groups/epics/show'
        end

        it 'logs the view with Gitlab::Search::RecentEpics' do
          group.add_developer(user)

          recent_epics_double = instance_double(::Gitlab::Search::RecentEpics, log_view: nil)
          expect(::Gitlab::Search::RecentEpics).to receive(:new).with(user: user).and_return(recent_epics_double)

          show_epic

          expect(response).to be_successful
          expect(recent_epics_double).to have_received(:log_view).with(epic)
        end

        context 'with unauthorized user' do
          it 'returns a not found 404 response' do
            show_epic

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.media_type).to eq 'text/html'
          end
        end

        it_behaves_like 'disabled when using an external authorization service' do
          subject { show_epic }

          before do
            group.add_developer(user)
          end
        end
      end

      context 'when format is JSON' do
        it 'returns epic' do
          group.add_developer(user)
          show_epic(:json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('entities/epic', dir: 'ee')
        end

        context 'with unauthorized user' do
          it 'returns a not found 404 response' do
            show_epic(:json)

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.media_type).to eq 'application/json'
          end
        end
      end
    end

    describe 'PUT #update' do
      let(:date) { Date.new(2002, 1, 1) }
      let(:params) do
        {
          title: 'New title',
          label_ids: [label.id],
          start_date_fixed: '2002-01-01',
          start_date_is_fixed: true,
          confidential: true
        }
      end

      before do
        group.add_developer(user)
      end

      context 'with correct basic params' do
        it 'returns status 200' do
          update_epic(epic, params)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates the epic correctly' do
          update_epic(epic, params)

          expect(epic.reload).to have_attributes(
            title: 'New title',
            labels: [label],
            start_date_fixed: date,
            start_date: date,
            start_date_is_fixed: true,
            state: 'opened',
            confidential: true
          )
        end
      end

      context 'when state_event param is close' do
        it 'allows epic to be closed' do
          update_epic(epic, params.merge(state_event: 'close'))

          epic.reload

          expect(epic).to be_closed
          expect(epic.closed_at).not_to be_nil
          expect(epic.closed_by).to eq(user)
        end
      end

      context 'when state_event param is reopen' do
        before do
          epic.update!(state: 'closed', closed_at: Time.current, closed_by: user)
        end

        it 'allows epic to be reopened' do
          update_epic(epic, params.merge(state_event: 'reopen'))

          epic.reload

          expect(epic).to be_opened
          expect(epic.closed_at).to be_nil
          expect(epic.closed_by).to be_nil
        end
      end

      def update_epic(epic, params)
        put :update, params: { group_id: epic.group.to_param, id: epic.to_param, epic: params }, format: :json
      end
    end

    describe 'GET #realtime_changes' do
      subject { get :realtime_changes, params: { group_id: group, id: epic.to_param } }

      it 'returns epic' do
        group.add_developer(user)
        subject

        expect(response.media_type).to eq 'application/json'
        expect(json_response).to include('title_text', 'title', 'description', 'description_text')
      end

      context 'with unauthorized user' do
        it 'returns a not found 404 response' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it_behaves_like 'disabled when using an external authorization service' do
        before do
          group.add_developer(user)
        end
      end
    end

    describe '#create' do
      subject do
        post :create, params: { group_id: group,
                                epic: { title: 'new epic',
                                        description: 'some descripition',
                                        label_ids: [label.id],
                                        confidential: true } }
      end

      context 'when user has permissions to create an epic' do
        before do
          group.add_developer(user)
        end

        context 'when all required parameters are passed' do
          it 'returns 200 response' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'creates a new epic' do
            expect { subject }.to change { Epic.count }.from(0).to(1)
          end

          it 'assigns labels to the new epic' do
            expect { subject }.to change { LabelLink.count }.from(0).to(1)
          end

          it 'returns the correct json' do
            subject

            expect(json_response).to eq({ 'web_url' => group_epic_path(group, Epic.last) })
          end

          it_behaves_like 'disabled when using an external authorization service'
        end

        context 'when required parameter is missing' do
          before do
            post :create, params: { group_id: group, epic: { description: 'some descripition' } }
          end

          it 'returns 422 response' do
            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end

          it 'does not create a new epic' do
            expect(Epic.count).to eq(0)
          end
        end

        context 'when the endpoint receives requests above the limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
          before do
            stub_application_setting(issues_create_limit: 1)
          end

          it 'prevents from creating more epics' do
            2.times { post :create, params: { group_id: group, epic: { title: 'new epic', description: 'description' } } }

            expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
            expect(response).to have_gitlab_http_status(:too_many_requests)
          end

          it 'logs the event on auth.log' do
            attributes = {
              message: 'Application_Rate_Limiter_Request',
              env: :issues_create_request_limit,
              remote_ip: '0.0.0.0',
              request_method: 'POST',
              path: group_epics_path(group),
              user_id: user.id,
              username: user.username
            }

            expect(Gitlab::AuthLogger).to receive(:error).with(attributes).once

            2.times { post :create, params: { group_id: group, epic: { title: 'new epic', description: 'description' } } }
          end
        end
      end

      context 'with unauthorized user' do
        it 'returns a not found 404 response' do
          group.add_guest(user)
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe "DELETE #destroy" do
      before do
        sign_in(user)
      end

      it "rejects a developer to destroy an epic" do
        group.add_developer(user)
        delete :destroy, params: { group_id: group, id: epic.to_param, destroy_confirm: true }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "deletes the epic" do
        group.add_owner(user)
        delete :destroy, params: { group_id: group, id: epic.to_param, destroy_confirm: true }

        expect(response).to have_gitlab_http_status(:see_other)
        expect(controller).to set_flash[:notice].to(/The epic was successfully deleted\./)
      end
    end

    describe 'POST #bulk_update' do
      context 'with correct params' do
        subject { post :bulk_update, params: params, format: :json }

        let(:label1) { create(:group_label, group: group) }
        let(:label2) { create(:group_label, group: group) }
        let(:epics)  { create_list(:epic, 2, group: group, labels: [label1]) }
        let(:params) do
          {
            update: {
              add_label_ids: [label2],
              issuable_ids: "#{epics[0].id}, #{epics[1].id}",
              remove_label_ids: [label1]
            },
            group_id: group
          }
        end

        before do
          sign_in(user)
          group.add_reporter(user)
        end

        context 'when group bulk edit feature is disabled' do
          before do
            stub_licensed_features(group_bulk_edit: false, epics: true)
            group.add_reporter(user)
          end

          it 'returns status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end

          it 'does not update merge requests milestone' do
            subject

            epics.each { |epic| expect(epic.reload.labels).to eq([label1]) }
          end
        end

        context 'when group bulk edit feature is enabled' do
          before do
            stub_licensed_features(group_bulk_edit: true, epics: true)
          end

          it 'returns status 200' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'updates epics labels' do
            subject

            epics.each { |epic| expect(epic.reload.labels).to eq([label2]) }
          end
        end
      end
    end
  end

  it_behaves_like DescriptionDiffActions do
    let_it_be(:group)    { create(:group, :public) }
    let_it_be(:issuable) { create(:epic, group: group) }

    let(:base_params) { { group_id: group, id: issuable } }
  end
end
