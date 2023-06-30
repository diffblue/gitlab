# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::ConfigurationFilter, feature_category: :value_stream_management do
  def include_dora_charts?(config)
    config.any? do |_, dashboard|
      dashboard[:charts].any? do |chart|
        chart[:query][:data_source] == 'dora'
      end
    end
  end

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  context 'when configuration is default' do
    let_it_be(:user) { create(:user) }

    subject { described_class.new(insights_entity: entity, config: entity.insights_config, user: user).execute }

    shared_examples 'filtering default config' do
      context 'when user cannot read all charts' do
        it 'does not include dora metrics charts' do
          expect(include_dora_charts?(subject)).to eq(false)
        end
      end

      context 'when user can read all charts' do
        before do
          entity.add_reporter(user)
        end

        it 'includes all charts' do
          expect(subject).to eq(entity.insights_config)
        end
      end
    end

    context 'for projects' do
      let_it_be_with_refind(:entity) { create(:project) }

      it_behaves_like 'filtering default config'
    end

    context 'for groups' do
      let_it_be_with_refind(:entity) { create(:group) }

      it_behaves_like 'filtering default config'
    end
  end

  context 'when using a custom configuration' do
    let_it_be(:user) { create(:user) }
    let_it_be(:entity) { create(:group) }

    let(:dora_1) do
      {
        title: 'dora_1',
        type: 'bar',
        query: {
          data_source: 'dora',
          params: {
            metric: 'deployment_frequency'
          }
        }
      }
    end

    let(:dora_2) do
      {
        title: 'dora_1',
        type: 'bar',
        query: {
          data_source: 'dora',
          params: {
            metric: 'lead_time_for_changes'
          }
        }
      }
    end

    let(:issue_chart) do
      {
        title: 'Issue chart',
        type: 'bar',
        query: {
          data_source: 'issuables',
          params: {
            issuable_type: 'issue'
          }
        }
      }
    end

    let(:config) do
      {
        item1: {
          title: 'Has DORA',
          charts: [
            dora_1,
            dora_2
          ]
        },

        item2: {
          title: 'Not DORA',
          charts: [issue_chart]
        },

        item3: {
          title: 'Mixed',
          charts: [
            issue_chart,
            dora_1
          ]
        }
      }
    end

    subject { described_class.new(insights_entity: entity, config: config, user: user).execute }

    context 'when a dashboard has only unauthorized charts' do
      it 'removes the dashboard' do
        expect(subject.keys).not_to include(:item1)
      end
    end

    context 'when a dashboard has authorized and unauthorized charts' do
      it 'keeps only authorized charts' do
        expect(subject[:item2][:charts]).to match_array([issue_chart])
        expect(subject[:item3][:charts]).to match_array([issue_chart])
      end
    end

    context 'when all dashboard charts are authorized' do
      before_all do
        entity.add_reporter(user)
      end

      it 'keeps all charts of the dashboards' do
        expect(subject).to eq(config)
      end
    end
  end
end
