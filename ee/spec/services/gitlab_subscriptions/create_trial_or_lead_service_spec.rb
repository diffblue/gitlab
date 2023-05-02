# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CreateTrialOrLeadService, feature_category: :billing_and_payments do
  let(:user) { build(:user, last_name: 'Jones') }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    let(:base_params) do
      {
        uid: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        work_email: user.email,
        setup_for_company: user.setup_for_company,
        newsletter_segment: user.email_opted_in,
        provider: 'gitlab',
        skip_email_confirmation: true,
        gitlab_com_trial: true,
        jtbd: '_jtbd_',
        comment: '_comment_'
      }
    end

    shared_examples 'correct client attributes' do
      let(:params) do
        base_params.merge(jtbd: nil, trial_onboarding_flow: trial_onboarding_flow)
      end

      let(:service_params) do
        params.merge({ glm_source: 'some_source', glm_content: 'some_content' })
      end

      before do
        subscription_portal_url = ::Gitlab::Routing.url_helpers.subscription_portal_url

        stub_request(:post, "#{subscription_portal_url}/trials#{path}")
      end

      it do
        expect(Gitlab::SubscriptionPortal::Client)
          .to receive(client_method)
          .with(params.merge(client_params))
          .and_call_original

        described_class.new(user: user, params: service_params).execute
      end
    end

    context 'when creating a trial' do
      let(:path) { '' }
      let(:client_method) { :generate_trial }
      let(:trial_onboarding_flow) { true }

      it_behaves_like 'correct client attributes' do
        let(:client_params) do
          {
            product_interaction: 'SaaS Trial',
            glm_source: 'some_source',
            glm_content: 'some_content'
          }
        end
      end
    end

    context 'when creating a lead' do
      let(:path) { '/create_hand_raise_lead' }
      let(:client_method) { :generate_lead }
      let(:trial_onboarding_flow) { false }

      it_behaves_like 'correct client attributes' do
        let(:client_params) { { product_interaction: 'SaaS Registration' } }
      end
    end

    where(:trial_onboarding_flow, :service, :interaction) do
      'true'  | :generate_trial | 'SaaS Trial'
      'false' | :generate_lead  | 'SaaS Registration'
    end

    with_them do
      it 'successfully creates a trial or lead' do
        allow(Gitlab::SubscriptionPortal::Client).to receive(service)
          .with(base_params.merge(product_interaction: interaction, trial_onboarding_flow: trial_onboarding_flow))
          .and_return({ success: true })

        result = described_class.new(user: user, params: {
          trial_onboarding_flow: trial_onboarding_flow,
          jobs_to_be_done_other: '_comment_',
          registration_objective: '_jtbd_'
        }).execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be true
      end

      it 'error while creating trial or lead' do
        allow(Gitlab::SubscriptionPortal::Client).to receive(service).and_return({ success: false })

        result = described_class.new(user: user, params: { trial_onboarding_flow: trial_onboarding_flow }).execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be false
      end
    end
  end
end
