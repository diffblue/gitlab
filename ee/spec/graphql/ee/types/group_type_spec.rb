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

  describe 'vulnerabilities' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:vulnerability) do
      create(:vulnerability, :detected, :critical, project: project, title: 'A terrible one!')
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
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:user3) { create(:user) }
    let_it_be(:user4) { create(:user) }

    before do
      group.add_developer(user1)
      group.add_guest(user2)
      project.add_developer(user3)
      project.add_guest(user4)
    end

    it "returns billable users count including guests when no plan is provided" do
      query = <<~GQL
        query {
          group(fullPath: "#{group.full_path}") {
            id,
            billableMembersCount
          }
        }
      GQL

      result = GitlabSchema.execute(query, context: { current_user: user1 }).as_json

      billable_members_count = result.dig('data', 'group', 'billableMembersCount')

      expect(billable_members_count).to eq(4)
    end

    it "returns billable users count including guests when a plan that should include guests is provided" do
      query = <<~GQL
        query {
          group(fullPath: "#{group.full_path}") {
            id,
            billableMembersCount(requestedHostedPlan: "#{::Plan::SILVER}")
          }
        }
      GQL

      result = GitlabSchema.execute(query, context: { current_user: user1 }).as_json

      billable_members_count = result.dig('data', 'group', 'billableMembersCount')

      expect(billable_members_count).to eq(4)
    end

    it "returns billable users count excluding guests when a plan that should exclude guests is provided" do
      query = <<~GQL
        query {
          group(fullPath: "#{group.full_path}") {
            id,
            billableMembersCount(requestedHostedPlan: "#{::Plan::ULTIMATE}")
          }
        }
      GQL

      result = GitlabSchema.execute(query, context: { current_user: user1 }).as_json

      billable_members_count = result.dig('data', 'group', 'billableMembersCount')

      expect(billable_members_count).to eq(2)
    end
  end

  describe 'dora field' do
    subject { described_class.fields['dora'] }

    it { is_expected.to have_graphql_type(Types::DoraType) }
  end
end
