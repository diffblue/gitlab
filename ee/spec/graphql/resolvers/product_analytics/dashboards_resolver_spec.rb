# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProductAnalytics::DashboardsResolver, feature_category: :product_analytics do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: project, ctx: { current_user: user }, args: { slug: slug }) }

    let_it_be(:user) { create(:user) }
    let_it_be(:project) do
      create(:project, :with_product_analytics_dashboard,
        project_setting: build(:project_setting, product_analytics_instrumentation_key: 'test')
      )
    end

    let(:slug) { nil }

    before do
      stub_licensed_features(product_analytics: true)
    end

    context 'when user has guest access' do
      before do
        project.add_guest(user)
      end

      it { is_expected.to be_nil }

      context 'when slug is provided' do
        let(:slug) { 'dashboard_example_1' }

        it { is_expected.to be_nil }
      end
    end

    context 'when user has developer access' do
      before do
        project.add_developer(user)
      end

      it 'returns all dashboards including hardcoded ones' do
        expect(subject).to eq(project.product_analytics_dashboards)
        expect(subject.size).to eq(3)
      end

      context 'when project is not onboarded for product analytics' do
        before do
          project.project_setting.update!(product_analytics_instrumentation_key: nil)
        end

        it 'returns all dashboards excluding hardcoded ones' do
          expect(subject).to eq(project.product_analytics_dashboards)
          expect(subject.size).to eq(1)
        end
      end

      context 'when snowplow support is disabled' do
        before do
          stub_feature_flags(product_analytics_snowplow_support: false)
        end

        it 'returns all dashboards excluding hardcoded ones' do
          expect(subject).to eq(project.product_analytics_dashboards)
          expect(subject.size).to eq(1)
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(product_analytics_dashboards: false)
        end

        it { is_expected.to be_nil }
      end

      context 'when slug matches existing dashboard' do
        let(:slug) { 'dashboard_example_1' }

        it 'contains only one dashboard and it is the one with the matching slug' do
          expect(subject.size).to eq(1)
          expect(subject.first.slug).to eq(slug)
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(product_analytics_dashboards: false)
          end

          it { is_expected.to be_nil }
        end
      end

      context 'when path does not match existing dashboard' do
        let(:slug) { 'not_a_real_dashboard' }

        it 'returns no dashboard' do
          expect(subject).to be_empty
        end
      end
    end
  end
end
