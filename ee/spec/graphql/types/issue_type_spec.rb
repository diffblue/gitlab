# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Issue'] do
  it { expect(described_class).to have_graphql_field(:epic) }
  it { expect(described_class).to have_graphql_field(:iteration) }
  it { expect(described_class).to have_graphql_field(:weight) }
  it { expect(described_class).to have_graphql_field(:health_status) }
  it { expect(described_class).to have_graphql_field(:blocking_count) }
  it { expect(described_class).to have_graphql_field(:blocked) }
  it { expect(described_class).to have_graphql_field(:blocked_by_count) }
  it { expect(described_class).to have_graphql_field(:blocked_by_issues) }
  it { expect(described_class).to have_graphql_field(:sla_due_at) }
  it { expect(described_class).to have_graphql_field(:metric_images) }
  it { expect(described_class).to have_graphql_field(:escalation_policy) }

  context 'N+1 queries' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:project_path) { project.full_path }

    let!(:blocking_issue1) { create(:issue, project: project) }
    let!(:blocked_issue1) { create(:issue, project: project) }
    let!(:issue_link1) { create :issue_link, source: blocking_issue1, target: blocked_issue1, link_type: IssueLink::TYPE_BLOCKS }

    shared_examples 'avoids N+1 queries on blocked' do
      specify do
        # Warm up table schema and other data (e.g. SAML providers, license)
        GitlabSchema.execute(query, context: { current_user: user })

        control_count = ActiveRecord::QueryRecorder.new { GitlabSchema.execute(query, context: { current_user: user }) }.count

        blocked_issue2 = create(:issue, project: project)
        blocking_issue2 = create(:issue, project: project)
        create :issue_link, source: blocking_issue2, target: blocked_issue2, link_type: IssueLink::TYPE_BLOCKS

        project2 = create(:project, :public, group: group)
        create(:issue, project: project2)

        expect { GitlabSchema.execute(query, context: { current_user: user }) }.not_to exceed_query_limit(control_count)
      end
    end

    context 'group issues' do
      let(:query) do
        %(
          query{
            group(fullPath:"#{group.full_path}"){
              issues{
                nodes{
                  title
                  blocked
                }
              }
            }
          }
        )
      end

      it_behaves_like 'avoids N+1 queries on blocked'
    end

    context 'project issues' do
      let(:query) do
        %(
          query{
            project(fullPath:"#{project_path}"){
              issues{
                nodes{
                  title
                  blocked
                }
              }
            }
          }
        )
      end

      it_behaves_like 'avoids N+1 queries on blocked'
    end
  end
end
