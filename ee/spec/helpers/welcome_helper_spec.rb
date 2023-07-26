# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WelcomeHelper, feature_category: :onboarding do
  using RSpec::Parameterized::TableSyntax

  let(:onboarding_status) { ::Onboarding::Status.new({}, {}, build_stubbed(:user)) }

  before do
    allow(helper).to receive(:onboarding_status).and_return(onboarding_status)
  end

  describe '#setup_for_company_label_text' do
    before do
      allow(onboarding_status).to receive(:subscription?).and_return(subscription?)
      allow(onboarding_status).to receive(:trial?).and_return(trial?)
    end

    subject { helper.setup_for_company_label_text }

    where(:subscription?, :trial?, :text) do
      true  | true  | 'Who will be using this GitLab subscription?'
      true  | false | 'Who will be using this GitLab subscription?'
      false | true  | 'Who will be using this GitLab trial?'
      false | false | 'Who will be using GitLab?'
    end

    with_them do
      it { is_expected.to eq(text) }
    end
  end

  shared_context 'with the various user flows' do
    let(:subscription?) { false }
    let(:invite?) { false }
    let(:oauth?) { false }
    let(:trial?) { false }

    before do
      allow(onboarding_status).to receive(:subscription?).and_return(subscription?)
      allow(onboarding_status).to receive(:invite?).and_return(invite?)
      allow(onboarding_status).to receive(:oauth?).and_return(oauth?)
    end
  end

  shared_context 'with signup onboarding' do
    let(:signup_onboarding_enabled) { false }

    before do
      allow(onboarding_status).to receive(:enabled?).and_return(signup_onboarding_enabled)
    end
  end

  describe '#welcome_submit_button_text' do
    include_context 'with the various user flows'
    include_context 'with signup onboarding'

    subject { helper.welcome_submit_button_text }

    context 'when in the subscription flow and signup onboarding is toggled' do
      where(:subscription?, :signup_onboarding_enabled, :button_text) do
        true  | true  | 'Continue'
        true  | false | 'Continue'
        false | true  | 'Continue'
        false | false | 'Get started!'
      end

      with_them do
        it { is_expected.to eq(button_text) }
      end
    end

    context 'when not in the subscription flow' do
      context 'and in the invitation or oauth flow' do
        where(:invite?, :oauth?) do
          true  | false
          false | true
        end

        with_them do
          context 'and regardless of signup onboarding' do
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
end
