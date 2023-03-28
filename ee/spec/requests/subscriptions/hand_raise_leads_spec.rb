# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Hand Raise Leads', :saas, feature_category: :purchase do
  describe 'POST /-/subscriptions/hand_raise_leads' do
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { create(:group).tap { |record| record.add_developer(user) } }
    let_it_be(:namespace_id) { namespace.id.to_s }

    let(:hand_raise_lead_result) { ServiceResponse.success }
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

    subject(:post_hand_raise_lead) do
      post subscriptions_hand_raise_leads_path, params: post_params
      response
    end

    before do
      allow_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
        allow(service).to receive(:execute).and_return(hand_raise_lead_result)
      end
    end

    context 'when authenticated' do
      before do
        sign_in(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'calls the hand raise lead service with correct parameters' do
        hand_raise_lead_extra_params =
          {
            work_email: user.email,
            uid: user.id,
            provider: 'gitlab',
            setup_for_company: user.setup_for_company,
            glm_source: 'gitlab.com'
          }
        expect_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
          expected_params = ActionController::Parameters.new(post_params)
                                                        .permit!
                                                        .merge(hand_raise_lead_extra_params)
          expect(service).to receive(:execute).with(expected_params).and_return(ServiceResponse.success)
        end

        post_hand_raise_lead
      end

      context 'when not on gitlab.com' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when namespace cannot be found' do
        let(:namespace_id) { non_existing_record_id.to_s }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'with failure' do
        let(:hand_raise_lead_result) { ServiceResponse.error(message: '_fail_') }

        it { is_expected.to have_gitlab_http_status(:forbidden) }
      end
    end

    context 'when not authenticated' do
      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
