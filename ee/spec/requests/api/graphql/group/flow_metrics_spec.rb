# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting group flow metrics', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }
  let_it_be(:current_user) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:production_environment1) { create(:environment, :production, project: project1) }
  let_it_be(:production_environment2) { create(:environment, :production, project: project2) }
  let_it_be(:other_group) { create(:group) }

  let(:full_path) { group.full_path }
  let(:context) { :group }

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)
  end

  shared_examples 'unavailable when unlicensed' do
    context 'when cycle analytics is not licensed' do
      before do
        stub_licensed_features(cycle_analytics_for_groups: false)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end

  it_behaves_like 'value stream analytics flow metrics issueCount examples' do
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

    it_behaves_like 'unavailable when unlicensed'
  end

  it_behaves_like 'value stream analytics flow metrics deploymentCount examples' do
    let(:deployments) { [deployment1, deployment2, deployment3] }

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      deployments.each do |deployment|
        Dora::DailyMetrics.refresh!(deployment.environment, deployment.finished_at.to_date)
      end
    end

    context 'when filtering the project ids' do
      let(:query) do
        <<~QUERY
        query($path: ID!, $projectIds: [ID!], $from: Time!, $to: Time!) {
          group(fullPath: $path) {
            flowMetrics {
              deploymentCount(projectIds: $projectIds, from: $from, to: $to) {
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

      before do
        variables[:projectIds] = [project1.id]
      end

      it 'returns 1' do
        expect(result).to eq({
          'identifier' => 'deploys',
          'unit' => nil,
          'value' => 1,
          'title' => n_('Deploy', 'Deploys', 1)
        })
      end
    end

    context 'when counting deployments for a different group' do
      let(:full_path) { other_group.full_path }

      it 'returns 0 count' do
        other_group.add_developer(current_user)

        expect(result).to match(a_hash_including({ 'value' => 0 }))
      end
    end

    it_behaves_like 'unavailable when unlicensed'
  end

  it_behaves_like 'value stream analytics flow metrics leadTime examples' do
    context 'when filtering the project ids' do
      let(:query) do
        <<~QUERY
          query($path: ID!, $projectIds: [ID!], $from: Time!, $to: Time!) {
            group(fullPath: $path) {
              flowMetrics {
                leadTime(projectIds: $projectIds, from: $from, to: $to) {
                  value
                }
              }
            }
          }
        QUERY
      end

      let(:variables) do
        {
          path: full_path,
          from: 16.days.ago.iso8601,
          to: 10.days.ago.iso8601,
          projectIds: [project1.id]
        }
      end

      it 'returns the correct count' do
        expect(result).to eq({ 'value' => 4 })
      end
    end

    it_behaves_like 'unavailable when unlicensed'
  end

  it_behaves_like 'value stream analytics flow metrics cycleTime examples' do
    context 'when filtering the project ids' do
      let(:query) do
        <<~QUERY
          query($path: ID!, $projectIds: [ID!], $from: Time!, $to: Time!) {
            group(fullPath: $path) {
              flowMetrics {
                cycleTime(projectIds: $projectIds, from: $from, to: $to) {
                  value
                }
              }
            }
          }
        QUERY
      end

      let(:variables) do
        {
          path: full_path,
          from: 16.days.ago.iso8601,
          to: 10.days.ago.iso8601,
          projectIds: [project1.id]
        }
      end

      it 'returns the correct count' do
        expect(result).to eq({ 'value' => 4 })
      end
    end

    it_behaves_like 'unavailable when unlicensed'
  end

  it_behaves_like 'value stream analytics flow metrics issuesCompleted examples' do
    context 'when filtering the project ids' do
      let(:query) do
        <<~QUERY
          query($path: ID!, $projectIds: [ID!], $from: Time!, $to: Time!) {
            group(fullPath: $path) {
              flowMetrics {
                issuesCompletedCount(projectIds: $projectIds, from: $from, to: $to) {
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
          'identifier' => 'issues_completed',
          'unit' => n_('issue', 'issues', 2),
          'value' => 2,
          'title' => "Issues Completed"
        })
      end
    end

    it_behaves_like 'unavailable when unlicensed'
  end
end
