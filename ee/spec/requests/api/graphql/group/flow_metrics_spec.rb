# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project flow metrics', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user).tap { |u| group.add_developer(u) } }

  it_behaves_like 'value stream analytics flow metrics issueCount examples' do
    let(:full_path) { group.full_path }
    let(:context) { :group }

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    context 'when filtering the project ids' do
      let(:query) do
        <<~QUERY
          query($path: ID!, $projectIds: [ID!], $from: Time!, $to: Time!) {
            group(fullPath: $path) {
              flowMetrics {
                issueCount(projectIds: $projectIds, from: $from, to: $to) {
                  value
                  unit
                  identifier
                  title
                }
              }
            }
          }
        QUERY
      end

      let(:variables) do
        {
          path: full_path,
          from: 20.days.ago.iso8601,
          to: 10.days.ago.iso8601,
          projectIds: [project1.id]
        }
      end

      it 'returns the correct count' do
        expect(result).to eq({
          'identifier' => 'issues',
          'unit' => nil,
          'value' => 2,
          'title' => n_('New Issue', 'New Issues', 2)
        })
      end
    end

    context 'when cycle analytics is not licensed' do
      before do
        stub_licensed_features(cycle_analytics_for_groups: false)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end
end
