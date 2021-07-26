# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::WelcomeHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#in_subscription_flow?' do
    where(:user_return_to_path, :expected_result) do
      '/-/subscriptions/new?plan_id=bronze_plan' | true
      '/foo'                                     | false
      nil                                        | false
    end

    with_them do
      it 'returns the expected_result' do
        allow(helper).to receive(:session).and_return('user_return_to' => user_return_to_path)

        expect(helper.in_subscription_flow?).to eq(expected_result)
      end
    end
  end

  describe '#in_trial_flow?' do
    where(:user_return_to_path, :expected_result) do
      '/-/trials/new?glm_content=free-trial&glm_source=about.gitlab.com' | true
      '/foo'                                                             | false
      nil                                                                | false
    end

    with_them do
      it 'returns the expected_result' do
        allow(helper).to receive(:session).and_return('user_return_to' => user_return_to_path)

        expect(helper.in_trial_flow?).to eq(expected_result)
      end
    end
  end

  describe '#show_trial_during_signup?' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    where(:setup_for_company, :expected_result) do
      true  | true
      false | false
    end

    with_them do
      let(:user) { create(:user, setup_for_company: setup_for_company) }

      it 'returns the expected_result' do
        expect(helper.show_trial_during_signup?).to eq(expected_result)
      end
    end
  end

  describe '#in_oauth_flow?' do
    where(:user_return_to_path, :expected_result) do
      '/oauth/authorize?client_id=x&redirect_uri=y&response_type=code&state=z' | true
      '/foo'                                                                   | false
      nil                                                                      | nil
    end

    with_them do
      it 'returns the expected_result' do
        allow(helper).to receive(:session).and_return('user_return_to' => user_return_to_path)

        expect(helper.in_oauth_flow?).to eq(expected_result)
      end
    end
  end

  describe '#setup_for_company_label_text' do
    before do
      allow(helper).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
      allow(helper).to receive(:in_trial_flow?).and_return(in_trial_flow)
    end

    subject { helper.setup_for_company_label_text }

    where(:in_subscription_flow, :in_trial_flow, :text) do
      true | true | 'Who will be using this GitLab subscription?'
      true | false | 'Who will be using this GitLab subscription?'
      false | true | 'Who will be using this GitLab trial?'
      false | false | 'Who will be using GitLab?'
    end

    with_them do
      it { is_expected.to eq(text) }
    end
  end

  shared_context 'with the various user flows' do
    let(:in_subscription_flow) { false }
    let(:user_has_memberships) { false }
    let(:in_oauth_flow) { false }
    let(:in_trial_flow) { false }

    before do
      allow(helper).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
      allow(helper).to receive(:user_has_memberships?).and_return(user_has_memberships)
      allow(helper).to receive(:in_oauth_flow?).and_return(in_oauth_flow)
      allow(helper).to receive(:in_trial_flow?).and_return(in_trial_flow)
    end
  end

  shared_context 'with signup onboarding' do
    let(:signup_onboarding_enabled) { false }

    before do
      allow(helper).to receive(:signup_onboarding_enabled?).and_return(signup_onboarding_enabled)
    end
  end

  describe '#show_signup_flow_progress_bar?' do
    include_context 'with the various user flows'
    include_context 'with signup onboarding'

    subject { helper.show_signup_flow_progress_bar? }

    context 'when in the subscription flow, regardless of all other flows' do
      let(:in_subscription_flow) { true }

      where(:user_has_memberships, :in_oauth_flow, :in_trial_flow) do
        true  | false | false
        false | true  | false
        false | false | true
      end

      with_them do
        context 'regardless of signup onboarding' do
          where(signup_onboarding_enabled: [true, false])

          with_them do
            it { is_expected.to be_truthy }
          end
        end
      end
    end

    context 'when not in the subscription flow' do
      context 'but in the invitation, oauth, or trial flow' do
        where(:user_has_memberships, :in_oauth_flow, :in_trial_flow) do
          true  | false | false
          false | true  | false
          false | false | true
        end

        with_them do
          context 'regardless of signup onboarding' do
            where(signup_onboarding_enabled: [true, false])

            with_them do
              it { is_expected.to be_falsey }
            end
          end
        end
      end

      context 'and not in the invitation, oauth, or trial flow' do
        where(:signup_onboarding_enabled, :result) do
          true  | true
          false | false
        end

        with_them do
          it 'depends on whether or not signup onboarding is enabldd' do
            is_expected.to eq(result)
          end
        end
      end
    end
  end

  describe '#welcome_submit_button_text' do
    include_context 'with the various user flows'
    include_context 'with signup onboarding'

    subject { helper.welcome_submit_button_text }

    context 'when in the subscription or trial flow' do
      where(:in_subscription_flow, :in_trial_flow) do
        true  | false
        false | true
      end

      with_them do
        context 'regardless of signup onboarding' do
          where(signup_onboarding_enabled: [true, false])

          with_them do
            it { is_expected.to eq('Continue') }
          end
        end
      end
    end

    context 'when not in the subscription or trial flow' do
      context 'but in the invitation or oauth flow' do
        where(:user_has_memberships, :in_oauth_flow) do
          true  | false
          false | true
        end

        with_them do
          context 'regardless of signup onboarding' do
            where(signup_onboarding_enabled: [true, false])

            with_them do
              it { is_expected.to eq('Get started!') }
            end
          end
        end
      end

      context 'and not in the invitation or oauth flow' do
        where(:signup_onboarding_enabled, :result) do
          true  | 'Continue'
          false | 'Get started!'
        end

        with_them do
          it 'depends on whether or not signup onboarding is enabled' do
            is_expected.to eq(result)
          end
        end
      end
    end
  end

  describe '#data_attributes_for_progress_bar_js_component' do
    before do
      allow(helper).to receive(:in_subscription_flow?).and_return(options_enabled)
      allow(helper).to receive(:signup_onboarding_enabled?).and_return(options_enabled)
    end

    subject { helper.tag(:div, data: helper.data_attributes_for_progress_bar_js_component) }

    where(:options_enabled, :attr_values) do
      true  | 'true'
      false | 'false'
    end

    with_them do
      it 'always includes both attributes with stringified boolean values' do
        is_expected.to eq(%{<div data-is-in-subscription-flow="#{attr_values}" data-is-signup-onboarding-enabled="#{attr_values}" />})
      end
    end
  end

  describe '#user_has_memberships?' do
    let_it_be(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'is true when the current_user has memberships' do
      create(:project_member, user: user)

      expect(helper).to be_user_has_memberships
    end
    it 'is false when the current_user has no memberships' do
      expect(helper).not_to be_user_has_memberships
    end
  end

  describe '#in_trial_onboarding_flow?' do
    subject { helper.in_trial_onboarding_flow? }

    it 'returns true if query param trial_flow is set to true' do
      allow(helper).to receive(:params).and_return({ trial_onboarding_flow: 'true' })

      is_expected.to eq(true)
    end

    it 'returns true if query param trial_flow is not set' do
      allow(helper).to receive(:params).and_return({})

      is_expected.to eq(false)
    end
  end

  describe '#signup_onboarding_enabled?' do
    subject { helper.signup_onboarding_enabled? }

    where(:is_com, :result) do
      true  | true
      false | false
    end

    with_them do
      before do
        expect(Gitlab).to receive(:com?).and_return(is_com)
      end

      it { is_expected.to eq(result) }
    end
  end
end
