# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Funnel, feature_category: :product_analytics do
  let_it_be(:project) { create(:project, :with_product_analytics_funnel) }

  before do
    stub_licensed_features(product_analytics: true)
  end

  subject(:funnel) { project.product_analytics_funnels.first }

  it { is_expected.to validate_numericality_of(:seconds_to_convert) }

  describe '.for_project' do
    subject(:funnels) { described_class.for_project(project) }

    it 'returns a collection of funnels' do
      expect(funnels).to be_a(Array)
      expect(funnels.first).to be_a(described_class)
      expect(funnels.first.name).to eq('completed_purchase')
      expect(funnels.first.project).to eq(project)
      expect(funnels.first.seconds_to_convert).to eq(3600)
    end

    it 'has a collection of steps' do
      expect(funnels.first.steps.size).to eq(2)
      expect(funnels.first.steps).to be_a(Array)
      expect(funnels.first.steps.first).to be_a(ProductAnalytics::FunnelStep)
      expect(funnels.first.steps.first.name).to eq('view_page_1')
      expect(funnels.first.steps.first.target).to eq('/page1.html')
      expect(funnels.first.steps.first.action).to eq('pageview')
    end

    context 'when the funnel directory includes a file that is not a yaml file' do
      before do
        project.repository.create_file(
          project.creator,
          '.gitlab/product_analytics/funnels/randomfile.txt',
          'not a yaml file',
          message: 'Add funnel definition',
          branch_name: 'master'
        )
      end

      it 'does not include the file in the collection' do
        expect(funnels.size).to eq(1)
      end
    end

    context 'when the project does not have a funnels directory' do
      let_it_be(:project) { create(:project, :repository) }

      it { is_expected.to be_empty }
    end
  end

  describe '#to_sql' do
    subject { project.product_analytics_funnels.first.to_sql }

    context 'with jitsu' do
      before do
        stub_feature_flags(product_analytics_snowplow_support: false)
      end

      let(:query) do
        <<-SQL
      SELECT
        (SELECT max(utc_time) FROM jitsu) as x,
        windowFunnel(3600)(utc_time, doc_path = '/page1.html', doc_path = '/page2.html') as step
        FROM gitlab_project_#{project.id}.jitsu
        SQL
      end

      it { is_expected.to eq(query) }
    end

    context 'with snowplow' do
      before do
        stub_feature_flags(product_analytics_snowplow_support: true)
      end

      let(:query) do
        <<-SQL
      SELECT
        (SELECT max(derived_tstamp) FROM snowplow_events) as x,
        windowFunnel(3600)(toDateTime(derived_tstamp), page_urlpath = '/page1.html', page_urlpath = '/page2.html') as step
        FROM gitlab_project_#{project.id}.snowplow_events
        SQL
      end

      it { is_expected.to eq(query) }
    end
  end
end
