# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::HooksController, feature_category: :integrations do
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group_maintainer) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:user) { group_owner }

  before_all do
    group.add_owner(group_owner)
    group.add_maintainer(group_maintainer)
  end

  before do
    sign_in(user)
  end

  context 'with group_webhooks enabled' do
    before do
      stub_licensed_features(group_webhooks: true)
    end

    describe 'GET #index' do
      it 'is successful' do
        get :index, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'POST #create' do
      it 'sets all parameters' do
        hook_params = {
          # triggers
          job_events: true,
          confidential_issues_events: true,
          issues_events: true,
          merge_requests_events: true,
          note_events: true,
          pipeline_events: true,
          push_events: true,
          tag_push_events: true,
          wiki_page_events: true,
          deployment_events: true,
          member_events: true,
          subgroup_events: true,
          confidential_note_events: true,
          feature_flag_events: true,
          # editable attributes
          enable_ssl_verification: true,
          token: 'TEST TOKEN',
          url: 'http://example.com',
          push_events_branch_filter: 'filter-branch',
          url_variables: [
            { key: 'token', value: 'shh-secret!' }
          ]
        }

        post :create, params: { group_id: group.to_param, hook: hook_params }

        expect(response).to have_gitlab_http_status(:found)
        expect(group.hooks.size).to eq(1)
        expect(group.hooks.first).to have_attributes(hook_params.except(:url_variables))
        expect(group.hooks.first.url_variables).to eq('token' => 'shh-secret!')
      end

      it 'alerts the user if the new hook is invalid' do
        hook_params = {
          token: "TEST\nTOKEN",
          url: "http://example.com"
        }

        post :create, params: { group_id: group.to_param, hook: hook_params }

        expect(flash[:alert]).to be_present
        expect(group.hooks.count).to eq(0)
      end
    end

    describe 'GET #edit' do
      let(:hook) { create(:group_hook, group: group) }

      let(:params) do
        { group_id: group.to_param, id: hook }
      end

      render_views

      it 'assigns hook_logs' do
        get :edit, params: params

        expect(assigns[:hook]).to be_present
        expect(assigns[:hook_logs]).to be_empty
        it_renders_correctly
      end

      it 'handles when logs are present' do
        create_list(:web_hook_log, 3, web_hook: hook)

        get :edit, params: params

        expect(assigns[:hook]).to be_present
        expect(assigns[:hook_logs].count).to eq 3
        it_renders_correctly
      end

      it 'can paginate logs' do
        create_list(:web_hook_log, 21, web_hook: hook)

        get :edit, params: params.merge(page: 2)

        expect(assigns[:hook]).to be_present
        expect(assigns[:hook_logs].count).to eq 1
        it_renders_correctly
      end

      def it_renders_correctly
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(response).to render_template('shared/hook_logs/_index')
        expect(group.hooks.size).to eq(1)
      end
    end

    describe 'PATCH #update' do
      let_it_be(:hook) { create(:group_hook, group: group) }

      context 'valid params' do
        let(:hook_params) do
          {
            job_events: true,
            confidential_issues_events: true,
            enable_ssl_verification: true,
            issues_events: true,
            merge_requests_events: true,
            note_events: true,
            pipeline_events: true,
            push_events: true,
            tag_push_events: true,
            token: 'TEST TOKEN',
            url: 'http://example.com',
            wiki_page_events: true,
            deployment_events: true,
            releases_events: true,
            member_events: true,
            subgroup_events: true,
            url_variables: [
              { key: 'a', value: 'alpha' },
              { key: 'b', value: nil },
              { key: 'c', value: 'gamma' }
            ]
          }
        end

        it 'is successful' do
          hook.update!(url_variables: { 'a' => 'x', 'b' => 'z' })

          patch :update, params: { group_id: group.to_param, id: hook, hook: hook_params }

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(edit_group_hook_path(group, hook))
          expect(group.hooks.size).to eq(1)
          expect(hook.reload).to have_attributes(hook_params.except(:url_variables))
          expect(hook.url_variables).to eq(
            'a' => 'alpha',
            'c' => 'gamma'
          )
        end
      end

      context 'invalid params' do
        let(:hook_params) do
          {
            url: ''
          }
        end

        it 'renders "edit" template' do
          patch :update, params: { group_id: group.to_param, id: hook, hook: hook_params }

          expect(response).to have_gitlab_http_status(:ok)
          expect(flash[:notice]).to be_nil
          expect(response).to render_template(:edit)
          expect(group.hooks.size).to eq(1)
          expect(group.hooks.first).not_to have_attributes(hook_params)
        end
      end
    end

    describe 'POST #test', :clean_gitlab_redis_shared_state do
      let(:hook) { create(:group_hook, group: group) }
      let(:success_response) { ServiceResponse.success(payload: { http_status: 200 }) }

      context 'when testing a job hook' do
        let(:trigger) { 'job_events' }

        before do
          create(:project, :repository, group: group)
        end

        context 'where there are no jobs' do
          it 'reports the error' do
            post :test, params: { group_id: group.to_param, id: hook, trigger: trigger }

            expect(response).to have_gitlab_http_status(:found)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to eq('Hook execution failed: Ensure the project has CI jobs.')
          end
        end
      end

      context 'when group does not have a project' do
        it 'redirects back' do
          expect(TestHooks::ProjectService).not_to receive(:new)

          post :test, params: { group_id: group.to_param, id: hook }

          expect(response).to have_gitlab_http_status(:found)
          expect(flash[:alert]).to eq('Hook execution failed. Ensure the group has a project with commits.')
        end
      end

      context 'when group has a project' do
        before do
          create(:project, :repository, group: group)
        end

        context 'when "trigger" params is empty' do
          it 'defaults to "push_events"' do
            expect_next_instance_of(TestHooks::ProjectService, hook, user, 'push_events') do |service|
              expect(service).to receive(:execute).and_return(success_response)
            end

            post :test, params: { group_id: group.to_param, id: hook }

            expect(response).to have_gitlab_http_status(:found)
            expect(flash[:notice]).to eq('Hook executed successfully: HTTP 200')
          end
        end

        context 'when "trigger" params is set' do
          let(:trigger) { 'issue_hooks' }

          it 'uses it' do
            expect_next_instance_of(TestHooks::ProjectService, hook, user, trigger) do |service|
              expect(service).to receive(:execute).and_return(success_response)
            end

            post :test, params: { group_id: group.to_param, id: hook, trigger: trigger }

            expect(response).to have_gitlab_http_status(:found)
            expect(flash[:notice]).to eq('Hook executed successfully: HTTP 200')
          end
        end

        context 'when the endpoint receives requests above the limit' do
          before do
            allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
              .and_return(group_testing_hook: { threshold: 1, interval: 1.minute })
          end

          it 'prevents making test requests' do
            expect_next_instance_of(TestHooks::ProjectService) do |service|
              expect(service).to receive(:execute).and_return(success_response)
            end

            2.times { post :test, params: { group_id: group.to_param, id: hook } }

            expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
            expect(response).to have_gitlab_http_status(:too_many_requests)
          end
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:hook) { create(:group_hook, group: group) }
    let!(:log) { create(:web_hook_log, web_hook: hook) }
    let(:params) { { group_id: group.to_param, id: hook } }

    it_behaves_like 'Web hook destroyer'

    context 'When user is not logged in' do
      let(:user) { group_maintainer }

      it 'renders a 404' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'with group_webhooks disabled' do
    before do
      stub_licensed_features(group_webhooks: false)
    end

    describe 'GET #index' do
      it 'renders a 404' do
        get :index, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
