# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).product_analytics_events_stored',
  feature_category: :product_analytics_data_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          productAnalyticsEventsStored
        }
      }
    )
  end

  subject do
    post_graphql(query, current_user: user)
  end

  before_all do
    project.add_owner(user)
  end

  context 'when project does not have product analytics enabled' do
    it "returns zero" do
      subject

      expect(graphql_data.dig('project', 'productAnalyticsEventsStored')).to be_zero
    end
  end

  context 'when project does have product analytics enabled' do
    before do
      allow_next_instance_of(ProductAnalytics::Settings) do |instance|
        allow(instance).to receive(:enabled?).and_return(true)
      end
    end

    it 'queries the ProjectUsageData interface' do
      freeze_time do
        expect_next_instance_of(Analytics::ProductAnalytics::ProjectUsageData) do |instance|
          expect(instance)
            .to receive(:events_stored_count).with(year: Time.current.year, month: Time.current.month).once
        end

        subject
      end
    end

    context 'when user is not a project member' do
      let_it_be(:user) { create(:user) }

      it { is_expected.to be_nil }
    end

    context 'when setting a month and year' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              productAnalyticsEventsStored(year: 2021, month: 3)
            }
          }
        )
      end

      it 'queries the ProjectUsageData interface with the correct parameters' do
        expect_next_instance_of(Analytics::ProductAnalytics::ProjectUsageData) do |instance|
          expect(instance).to receive(:events_stored_count).with(year: 2021, month: 3).once
        end

        subject
      end
    end
  end
end
