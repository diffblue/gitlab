# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::OperationsController, feature_category: :incident_management do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  before_all do
    project.add_maintainer(user)
  end

  describe 'GET show' do
    shared_examples 'user without read access' do |project_visibility, project_role|
      before do
        project.update!(visibility: project_visibility.to_s)
        project.add_role(user, project_role)
      end

      it 'returns 404' do
        get :show, params: project_params(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples 'user with read access' do |project_visibility|
      before do
        project.update!(visibility: project_visibility.to_s)
        project.add_maintainer(user)
      end

      it 'renders ok' do
        get :show, params: project_params(project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end

    shared_examples 'user needs to login' do |project_visibility|
      before do
        project.update!(visibility: project_visibility.to_s)
      end

      it 'redirects for private project' do
        get :show, params: project_params(project)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with a license' do
      before do
        stub_licensed_features(status_page: true, incident_sla: true)
      end

      context 'with maintainer role' do
        it_behaves_like 'user with read access', :public
        it_behaves_like 'user with read access', :private
        it_behaves_like 'user with read access', :internal
      end

      context 'without maintainer role' do
        %w[guest reporter developer].each do |role|
          it_behaves_like 'user without read access', :public, role
          it_behaves_like 'user without read access', :private, role
          it_behaves_like 'user without read access', :internal, role
        end
      end

      context 'when user not logged in' do
        before do
          sign_out(user)
        end

        it_behaves_like 'user without read access', :public, :maintainer

        it_behaves_like 'user needs to login', :private
        it_behaves_like 'user needs to login', :internal
      end
    end

    context 'without license' do
      before do
        stub_licensed_features(status_page: false, incident_sla: false)
      end

      it_behaves_like 'user with read access', :public
      it_behaves_like 'user with read access', :private
      it_behaves_like 'user with read access', :internal
    end
  end

  describe 'PATCH update' do
    shared_examples 'user without write access' do |project_visibility, project_role|
      before do
        project.update!(visibility: project_visibility.to_s)
        project.add_role(user, project_role)
      end

      it 'does not create status_page_setting' do
        update_project(
          project,
          status_page_params: attributes_for(:status_page_setting)
        )

        expect(project.status_page_setting).to be_nil
      end
    end

    context 'with a license' do
      before do
        stub_licensed_features(status_page: true, incident_sla: true)
      end

      context 'with non maintainer roles' do
        %w[guest reporter developer].each do |role|
          context "with #{role} role" do
            it_behaves_like 'user without write access', :public, role
            it_behaves_like 'user without write access', :private, role
            it_behaves_like 'user without write access', :internal, role
          end
        end
      end

      context 'with anonymous user' do
        before do
          sign_out(user)
        end

        it_behaves_like 'user without write access', :public, :maintainer
        it_behaves_like 'user without write access', :private, :maintainer
        it_behaves_like 'user without write access', :internal, :maintainer
      end

      context 'without existing status page setting' do
        subject(:status_page_setting) do
          valid_attributes = attributes_for(:status_page_setting).except(:enabled)
          update_project(project, status_page_params: valid_attributes)

          project.status_page_setting
        end

        it { is_expected.to be_a(StatusPage::ProjectSetting) }
      end

      context 'with existing status page setting' do
        let(:status_page_attributes) { attributes_for(:status_page_setting) }

        before do
          project.create_status_page_setting!(status_page_attributes)
        end

        it 'updates the fields' do
          update_project(project, status_page_params: status_page_attributes.merge(aws_s3_bucket_name: 'test'))

          expect(project.status_page_setting.aws_s3_bucket_name).to eq('test')
        end

        it 'respects the model validations' do
          old_name = project.status_page_setting.aws_s3_bucket_name

          update_project(project, status_page_params: status_page_attributes.merge(aws_s3_bucket_name: ''))
          expect(project.status_page_setting.aws_s3_bucket_name).to eq(old_name)
        end

        it 'deletes the setting if keys removed' do
          update_project(
            project,
            status_page_params: status_page_attributes.merge(
              aws_access_key: '',
              aws_secret_key: '',
              aws_s3_bucket_name: '',
              aws_region: '',
              status_page_url: ''
            )
          )
          expect(project.status_page_setting).to be_nil
        end
      end

      context 'indident management settings' do
        let(:project) { create(:project) }

        let(:params) { attributes_for(:project_incident_management_setting) }

        subject(:incident_management_setting) do
          update_project(project, incident_management_params: params)

          project.incident_management_setting
        end

        before do
          project.add_maintainer(user)
        end

        shared_examples 'can set the sla timer settings' do
          let(:sla_settings) do
            {
              sla_timer: 'true',
              sla_timer_minutes: 60
            }
          end

          before do
            params.merge!(sla_settings)
          end

          it 'updates the sla settings' do
            setting = incident_management_setting

            expect(setting.sla_timer).to eq(true)
            expect(setting.sla_timer_minutes).to eq(60)
          end
        end

        context 'without existing incident management setting' do
          it { is_expected.to be_a(IncidentManagement::ProjectIncidentManagementSetting) }

          it_behaves_like 'can set the sla timer settings'
        end

        context 'with existing incident management setting' do
          before do
            create(:project_incident_management_setting, project: project)
          end

          it { is_expected.to be_a(IncidentManagement::ProjectIncidentManagementSetting) }

          it_behaves_like 'can set the sla timer settings'
        end
      end
    end

    context 'without a license' do
      let(:project) { create(:project) }

      before do
        project.add_maintainer(user)
        stub_licensed_features(status_page: false, incident_sla: false)
      end

      it_behaves_like 'user without write access', :public, :maintainer
      it_behaves_like 'user without write access', :private, :maintainer
      it_behaves_like 'user without write access', :internal, :maintainer

      it 'cannot update sla timer settings', :aggregate_failures do
        default_attributes = attributes_for(:project_incident_management_setting)

        sla_settings = {
          sla_timer: 'true',
          sla_timer_minutes: 60
        }

        update_project(project, incident_management_params: default_attributes.merge(sla_settings))

        setting = project.incident_management_setting

        expect(setting.sla_timer).to eq(default_attributes[:sla_timer])
        expect(setting.sla_timer_minutes).to eq(default_attributes[:sla_timer_minutes])
      end
    end

    private

    def update_project(project, incident_management_params: nil, status_page_params: nil)
      patch :update, params: project_params(
        project,
        status_page_params: status_page_params,
        incident_management_params: incident_management_params
      )

      project.reload
    end
  end

  private

  def project_params(project, incident_management_params: nil, status_page_params: nil)
    {
      namespace_id: project.namespace,
      project_id: project,
      project: {
        status_page_setting_attributes: status_page_params,
        incident_management_setting_attributes: incident_management_params
      }
    }
  end

  def stub_operations_update_service_returning(return_value = {})
    expect(::Projects::Operations::UpdateService)
      .to receive(:new).with(project, user, anything)
      .and_return(operations_update_service)
    expect(operations_update_service).to receive(:execute)
      .and_return(return_value)
  end
end
