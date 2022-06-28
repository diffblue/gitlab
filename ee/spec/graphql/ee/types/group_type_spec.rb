# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Group'] do
  describe 'nested epic request' do
    it { expect(described_class).to have_graphql_field(:epicsEnabled) }
    it { expect(described_class).to have_graphql_field(:epic) }
    it { expect(described_class).to have_graphql_field(:epics) }
    it { expect(described_class).to have_graphql_field(:epic_board) }
    it { expect(described_class).to have_graphql_field(:epic_boards) }
  end

  it { expect(described_class).to have_graphql_field(:iterations) }
  it { expect(described_class).to have_graphql_field(:iteration_cadences) }
  it { expect(described_class).to have_graphql_field(:vulnerabilities) }
  it { expect(described_class).to have_graphql_field(:vulnerability_scanners) }
  it { expect(described_class).to have_graphql_field(:vulnerabilities_count_by_day) }
  it { expect(described_class).to have_graphql_field(:vulnerability_grades) }
  it { expect(described_class).to have_graphql_field(:code_coverage_activities) }
  it { expect(described_class).to have_graphql_field(:stats) }
  it { expect(described_class).to have_graphql_field(:billable_members_count) }
  it { expect(described_class).to have_graphql_field(:external_audit_event_destinations) }
  it { expect(described_class).to have_graphql_field(:merge_request_violations) }
  it { expect(described_class).to have_graphql_field(:allow_stale_runner_pruning) }
  it { expect(described_class).to have_graphql_field(:cluster_agents) }
  it { expect(described_class).to have_graphql_field(:enforce_free_user_cap) }

  describe 'vulnerabilities' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:vulnerability) do
      create(:vulnerability, :detected, :critical, :with_finding, project: project, title: 'A terrible one!')
    end

    let_it_be(:query) do
      %(
        query {
          group(fullPath: "#{group.full_path}") {
            name
            vulnerabilities {
              nodes {
                title
                severity
                state
              }
            }
          }
        }
      )
    end

    before do
      stub_licensed_features(security_dashboard: true)

      group.add_developer(user)
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    it "returns the vulnerabilities for all projects in the group and its subgroups" do
      vulnerabilities = subject.dig('data', 'group', 'vulnerabilities', 'nodes')

      expect(vulnerabilities.count).to be(1)
      expect(vulnerabilities.first['title']).to eq('A terrible one!')
      expect(vulnerabilities.first['state']).to eq('DETECTED')
      expect(vulnerabilities.first['severity']).to eq('CRITICAL')
    end
  end

  describe 'billable members count' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:group_owner) { create(:user) }
    let_it_be(:group_developer) { create(:user) }
    let_it_be(:group_guest) { create(:user) }
    let_it_be(:project_developer) { create(:user) }
    let_it_be(:project_guest) { create(:user) }

    let(:current_user) { group_owner }
    let(:query) do
      <<~GQL
        query {
          group(fullPath: "#{group.full_path}") {
            id,
            billableMembersCount
          }
        }
      GQL
    end

    before do
      group.add_owner(group_owner)
      group.add_developer(group_developer)
      group.add_guest(group_guest)
      project.add_developer(project_developer)
      project.add_guest(project_guest)
    end

    subject(:billable_members_count) do
      result = GitlabSchema.execute(query, context: { current_user: current_user }).as_json

      result.dig('data', 'group', 'billableMembersCount')
    end

    context 'when no plan is provided' do
      it 'returns billable users count including guests' do
        expect(billable_members_count).to eq(5)
      end
    end

    context 'when a plan is provided' do
      let(:query) do
        <<~GQL
          query {
            group(fullPath: "#{group.full_path}") {
              id,
              billableMembersCount(requestedHostedPlan: "#{plan}")
            }
          }
        GQL
      end

      context 'with a plan that should include guests is provided' do
        let(:plan) { ::Plan::SILVER }

        it 'returns billable users count including guests' do
          expect(billable_members_count).to eq(5)
        end
      end

      context 'with a plan that should exclude guests is provided' do
        let(:plan) { ::Plan::ULTIMATE }

        it 'returns billable users count excluding guests when a plan that should exclude guests is provided' do
          expect(billable_members_count).to eq(3)
        end
      end
    end

    context 'without owner authorization' do
      let(:current_user) { group_developer }

      it 'does not return the billable members count' do
        expect(billable_members_count).to be_nil
      end
    end
  end

  describe 'dora field' do
    subject { described_class.fields['dora'] }

    it { is_expected.to have_graphql_type(Types::DoraType) }
  end
end
