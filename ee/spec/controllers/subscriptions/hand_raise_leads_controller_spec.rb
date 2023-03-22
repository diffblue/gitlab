# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::HandRaiseLeadsController, :saas, feature_category: :purchase do
  let_it_be(:user) { create(:user) }

  let(:logged_in) { true }

  before do
    sign_in(user) if logged_in
  end

  describe '#create' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:namespace_id) { namespace.id.to_s }

    let(:create_hand_raise_lead_result) { ServiceResponse.success }
    let(:hand_raise_lead_extra_params) do
      {
        work_email: user.email,
        uid: user.id,
        provider: 'gitlab',
        setup_for_company: user.setup_for_company,
        glm_source: 'gitlab.com'
      }
    end

    let(:post_params) do
      {
        namespace_id: namespace_id,
        first_name: 'James',
        last_name: 'Bond',
        company_name: 'ACME',
        company_size: '1-99',
        phone_number: '+1-192-10-10',
        country: 'US',
        state: 'CA',
        comment: 'I want to talk to sales.',
        glm_content: 'group-billing'
      }
    end

    subject do
      post :create, params: post_params
      response
    end

    before_all do
      namespace.add_developer(user)
    end

    before do
      allow_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
        allow(service).to receive(:execute).and_return(create_hand_raise_lead_result)
      end
    end

    context 'when not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com' do
      it { is_expected.to have_gitlab_http_status(:ok) }
    end

    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when cannot find the namespace' do
      let(:namespace_id) { non_existing_record_id.to_s }

      it 'returns 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when CreateHandRaiseLeadService fails' do
      let(:create_hand_raise_lead_result) { ServiceResponse.error(message: '_fail_') }

      it 'returns 403' do
        is_expected.to have_gitlab_http_status(:forbidden)
      end
    end

    it 'calls the CreateHandRaiseLeadService with correct parameters' do
      expect_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
        expected_params = ActionController::Parameters.new(post_params)
                            .permit!
                            .merge(hand_raise_lead_extra_params)
        expect(service).to receive(:execute).with(expected_params).and_return(ServiceResponse.success)
      end

      post :create, params: post_params
    end
  end
end
