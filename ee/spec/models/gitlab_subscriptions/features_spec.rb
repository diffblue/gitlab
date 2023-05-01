# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Features do
  describe 'License -> Plan mapping' do
    (::Plan.all_plans - ::Plan.default_plans).each do |plan_name|
      describe "#{plan_name} plan" do
        it 'is mapped to a license tier' do
          expect(described_class::LICENSE_PLANS_TO_SAAS_PLANS.values.flatten).to include(plan_name)
        end
      end
    end
  end

  describe '.plans_with_feature' do
    subject { described_class.plans_with_feature(feature) }

    it 'starter feature is in all plans' do
      (described_class::STARTER_FEATURES - described_class::GLOBAL_FEATURES).each do |feature|
        expectd_plans = described_class.plans_with_feature(feature)
        expect(expectd_plans).to contain_exactly(License::STARTER_PLAN, License::PREMIUM_PLAN, License::ULTIMATE_PLAN)
      end
    end

    it 'premium feature is in premium and ultimate plans' do
      (described_class::PREMIUM_FEATURES - described_class::GLOBAL_FEATURES).each do |feature|
        expectd_plans = described_class.plans_with_feature(feature)
        expect(expectd_plans).to contain_exactly(License::PREMIUM_PLAN, License::ULTIMATE_PLAN)
      end
    end

    it 'ultimate feature is in ultimate plan' do
      (described_class::ULTIMATE_FEATURES - described_class::GLOBAL_FEATURES).each do |feature|
        expectd_plans = described_class.plans_with_feature(feature)
        expect(expectd_plans).to contain_exactly(License::ULTIMATE_PLAN)
      end
    end

    context 'when param is a global feature' do
      let(:feature) { described_class::GLOBAL_FEATURES.sample }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'when feature does not exist' do
      let(:feature) { :does_not_exist }

      it { is_expected.to be_empty }
    end
  end

  describe '.saas_plans_with_feature' do
    subject { described_class.saas_plans_with_feature(feature) }

    context 'a Starter feature' do
      let(:feature) { :audit_events }

      it 'is present in all paid plans' do
        expect(subject).to contain_exactly(*::Plan::PAID_HOSTED_PLANS)
      end
    end

    context 'a Premium feature' do
      let(:feature) { :epics }

      it 'is present in all Premium+ plans' do
        expected_plans = ::Plan::PAID_HOSTED_PLANS - [::Plan::BRONZE]
        expect(subject).to contain_exactly(*expected_plans)
      end
    end

    context 'an Ultimate feature' do
      let(:feature) { :dast }

      it 'is present in all top plans' do
        expected_plans = ::Plan::PAID_HOSTED_PLANS - [::Plan::BRONZE, ::Plan::SILVER, ::Plan::PREMIUM, ::Plan::PREMIUM_TRIAL]
        expect(subject).to contain_exactly(*expected_plans)
      end
    end

    context 'a global feature' do
      let(:feature) { :elastic_search }

      it 'cannot be checked using this method' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'a non existing feature' do
      let(:feature) { :unknown_feature }

      it 'is not in any plan' do
        expect(subject).to be_empty
      end
    end
  end

  describe '.global?' do
    subject { described_class.global?(feature) }

    context 'when it is a global feature' do
      let(:feature) { :geo }

      it { is_expected.to be(true) }
    end

    context 'when it is not a global feature' do
      let(:feature) { :sast }

      it { is_expected.to be(false) }
    end
  end

  describe '.features' do
    subject(:features) { described_class.features(plan: plan, add_ons: add_ons) }

    let(:add_ons) { {} }

    let_it_be(:add_on_feature) { :geo }
    let_it_be(:geo_addon) { { 'GitLab_Geo' => 1 } }

    context 'when plan is Starter' do
      let(:plan) { License::STARTER_PLAN }

      it 'includes only Starter features' do
        expect(features).to include(*described_class::STARTER_FEATURES)
        expect(features.intersect?(described_class::PREMIUM_FEATURES.to_set)).to be(false)
        expect(features.intersect?(described_class::ULTIMATE_FEATURES.to_set)).to be(false)
      end

      context 'when add-ons are present' do
        let(:add_ons) { geo_addon }

        it 'includes Starter features and add-on features' do
          expect(features).to include(*described_class::STARTER_FEATURES)
          expect(features).to include(add_on_feature)
        end
      end
    end

    context 'when plan is Premium' do
      let(:plan) { License::PREMIUM_PLAN }

      it 'includes Starter and Premium features' do
        expect(features).to include(*described_class::STARTER_FEATURES)
        expect(features).to include(*described_class::PREMIUM_FEATURES)
        expect(features.intersect?(described_class::ULTIMATE_FEATURES.to_set)).to be(false)
      end

      context 'when add-ons are present' do
        let(:add_ons) { geo_addon }

        it 'includes Starter and Premium features and add-on features' do
          expect(features).to include(*described_class::STARTER_FEATURES)
          expect(features).to include(*described_class::PREMIUM_FEATURES)
          expect(features).to include(add_on_feature)
        end
      end
    end

    context 'when plan is Ultimate' do
      let(:plan) { License::ULTIMATE_PLAN }

      it 'includes Starter, Premium and Ultimate features' do
        expect(features).to include(*described_class::STARTER_FEATURES)
        expect(features).to include(*described_class::PREMIUM_FEATURES)
        expect(features).to include(*described_class::ULTIMATE_FEATURES)
      end

      context 'when add-ons are present' do
        let(:add_ons) { geo_addon }

        it 'includes Starter, Premium and Ultimate features' do
          expect(features).to include(*described_class::STARTER_FEATURES)
          expect(features).to include(*described_class::PREMIUM_FEATURES)
          expect(features).to include(*described_class::ULTIMATE_FEATURES)
        end

        it 'includes also add-on features' do
          expect(features).to include(add_on_feature)
        end
      end
    end
  end

  describe '.usage_ping_feature?' do
    subject { described_class.usage_ping_feature?(feature) }

    let(:usage_ping_enabled) { true }

    before do
      stub_application_setting(usage_ping_features_enabled: usage_ping_enabled)
    end

    context 'when param is a Starter usage ping feature' do
      let(:feature) { described_class::STARTER_FEATURES_WITH_USAGE_PING.sample }

      it { is_expected.to be_truthy }

      context 'when usage ping setting is disabled' do
        let(:usage_ping_enabled) { false }

        it { is_expected.to be_falsey }
      end
    end

    context 'when param is a Premium usage ping feature' do
      let(:feature) { described_class::PREMIUM_FEATURES_WITH_USAGE_PING.sample }

      it { is_expected.to be_truthy }

      context 'when usage ping setting is disabled' do
        let(:usage_ping_enabled) { false }

        it { is_expected.to be_falsey }
      end
    end

    context 'when param is another usage ping feature' do
      let(:feature) { :audit_events }

      it { is_expected.to be_falsey }
    end
  end

  it 'ensures that there is no same names between licensed features and feature flags', :aggregate_failures do
    all_features = GitlabSubscriptions::Features::FEATURES_BY_PLAN.values.flatten

    all_features.each do |licensed_feature|
      # This is currently failing feature. Needs to be fixed by the responsible team
      next if licensed_feature == :group_protected_branches

      expect { Feature.enabled?(licensed_feature) }.to raise_error(Feature::InvalidFeatureFlagError),
        "Licensed feature '#{licensed_feature}' has a matching feature flag. Please rename the feature or the FF"
    end
  end
end
