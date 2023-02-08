# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProductAnalytics::VisualizationResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject do
      resolve(
        described_class, obj: project.product_analytics_dashboards.first.panels.first, ctx: { current_user: user }
      )
    end

    before do
      stub_licensed_features(product_analytics: true)
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :with_product_analytics_dashboard) }

    it 'returns the visualization object' do
      expect(subject).to be_a(ProductAnalytics::Visualization)
    end

    context 'when the visualization does not exist' do
      before do
        allow_next_instance_of(ProductAnalytics::Panel) do |panel|
          allow(panel).to receive(:visualization).and_return(nil)
        end
      end

      it 'raises an error' do
        expect(subject).to be_a(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
