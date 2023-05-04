# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialsController, :saas, feature_category: :purchase do
  let_it_be(:user) { create(:user, email_opted_in: true, last_name: 'Doe') }

  let(:logged_in) { true }

  before do
    sign_in(user) if logged_in
  end

  shared_examples 'an authenticated endpoint' do
    let(:success_status) { :ok }

    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to redirect_to(new_trial_registration_url) }
    end

    context 'when authenticated' do
      it { is_expected.to have_gitlab_http_status(success_status) }
    end
  end

  shared_examples 'a dot-com only feature' do
    let(:success_status) { :ok }

    context 'when not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com' do
      it { is_expected.to have_gitlab_http_status(success_status) }
    end
  end

  describe '#select' do
    subject(:get_select) do
      get :select
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'
  end

  describe '#apply' do
    let_it_be(:namespace) { create(:group, path: 'namespace-test') }

    let(:post_params) { { namespace_id: namespace.id } }
    let(:apply_trial_result) do
      instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.error(message: '_fail_'))
    end

    before do
      namespace.add_owner(user)

      allow(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(apply_trial_result)
      allow(controller).to receive(:experiment).and_call_original
    end

    subject(:post_apply) do
      post :apply, params: post_params
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'

    context 'with success' do
      let(:apply_trial_result) do
        instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.success)
      end

      it 'calls the ApplyTrialService with correct parameters' do
        gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }
        post_params = {
          namespace_id: namespace.id,
          trial_entity: 'company',
          glm_source: 'source',
          glm_content: 'content',
          namespace: namespace.slice(:id, :name, :path, :kind, :trial_ends_on)
        }
        apply_trial_params = {
          uid: user.id,
          trial_user_information: ActionController::Parameters.new(post_params).permit(
            :namespace_id,
            :trial_entity,
            :glm_source,
            :glm_content,
            namespace: [:id, :name, :path, :kind, :trial_ends_on]
          ).merge(gl_com_params)
        }

        expect_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService, apply_trial_params) do |instance|
          expect(instance).to receive(:execute).and_return(ServiceResponse.success)
        end

        post :apply, params: post_params
      end

      context 'with a new Group' do
        let(:post_params) { { new_group_name: 'GitLab' } }

        it 'creates the Group' do
          expect { post_apply }.to change { Group.count }.by(1)
        end
      end
    end

    context 'with failure' do
      let(:apply_trial_result) do
        instance_double(
          GitlabSubscriptions::Trials::ApplyTrialService,
          execute: ServiceResponse.error(message: '_failed_')
        )
      end

      it { is_expected.to render_template(:select) }

      it 'does not call the record conversion method for the experiments' do
        post_apply
      end

      context 'with a new Group' do
        let(:post_params) { { new_group_name: 'admin' } }

        it { is_expected.to render_template(:select) }

        it 'does not create the Group' do
          expect { post_apply }.not_to change { Group.count }
        end
      end
    end
  end
end
