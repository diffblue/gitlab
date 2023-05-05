# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::GonHelper do
  let(:helper) do
    Class.new do
      include Gitlab::GonHelper

      def current_user
        nil
      end
    end.new
  end

  describe '#add_gon_variables' do
    let(:gon) { double('gon').as_null_object }

    before do
      allow(helper).to receive(:gon).and_return(gon)
      allow(helper).to receive(:push_to_gon_attributes).and_return(nil)
      allow(helper).to receive(:current_user).and_return(create(:user))
    end

    it 'includes ee exclusive settings' do
      expect(gon).to receive(:roadmap_epics_limit=).with(1000)

      helper.add_gon_variables
    end

    it 'adds AI gon attributes' do
      ai_chat = {
        total_model_token: ::Llm::ExplainCodeService::TOTAL_MODEL_TOKEN_LIMIT,
        max_response_token: ::Llm::ExplainCodeService::MAX_RESPONSE_TOKENS,
        input_content_limit: ::Llm::ExplainCodeService::INPUT_CONTENT_LIMIT
      }
      helper.add_gon_variables

      expect(helper).to have_received(:push_to_gon_attributes).with('ai', 'chat', ai_chat)
    end

    context 'when GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'includes CustomersDot variables' do
        expect(gon).to receive(:subscriptions_url=).with(::Gitlab::Routing.url_helpers.subscription_portal_url)
        expect(gon).to receive(:subscriptions_legacy_sign_in_url=).with(::Gitlab::Routing.url_helpers.subscription_portal_legacy_sign_in_url)
        expect(gon).to receive(:payment_form_url=).with(::Gitlab::Routing.url_helpers.subscription_portal_payment_form_url)
        expect(gon).to receive(:payment_validation_form_id=).with(Gitlab::SubscriptionPortal::PAYMENT_VALIDATION_FORM_ID)
        expect(gon).to receive(:registration_validation_form_url=).with(::Gitlab::Routing.url_helpers.subscription_portal_registration_validation_form_url)

        helper.add_gon_variables
      end
    end
  end

  describe '#push_licensed_feature' do
    let_it_be(:feature) { GitlabSubscriptions::Features::ALL_FEATURES.first }

    shared_examples 'sets the licensed features flag' do
      it 'pushes the licensed feature flag to the frotnend' do
        gon = class_double('Gon')
        stub_licensed_features(feature => true)

        allow(helper)
          .to receive(:gon)
          .and_return(gon)

        expect(gon)
          .to receive(:push)
          .with({ licensed_features: { feature.to_s.camelize(:lower) => true } }, true)

        subject
      end
    end

    context 'no obj given' do
      subject { helper.push_licensed_feature(feature) }

      before do
        expect(License).to receive(:feature_available?).with(feature)
      end

      it_behaves_like 'sets the licensed features flag'
    end

    context 'obj given' do
      let(:project) { create(:project) }

      subject { helper.push_licensed_feature(feature, project) }

      before do
        expect(project).to receive(:feature_available?).with(feature).and_call_original
      end

      it_behaves_like 'sets the licensed features flag'
    end
  end
end
