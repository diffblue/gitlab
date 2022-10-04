# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Epics::DefaultProjectForIssueCreationResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:issue) { create(:issue, project: project1) }
  let_it_be(:issue2) { create(:issue, project: project2) }

  let_it_be(:other_group) { create(:group) }
  let_it_be(:project_outside_hierarchy) { create(:project, group: other_group) }
  let_it_be(:issue_outside_hierarchy) { create(:issue, project: project_outside_hierarchy) }

  let_it_be(:current_user) { user }

  let(:schema) do
    Class.new(GitlabSchema) do
      default_max_page_size 100
    end
  end

  before do
    stub_licensed_features(epics: true)

    group.add_developer(user)
    other_group.add_developer(user)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::ProjectType)
  end

  describe '#resolve' do
    subject(:default_project) { resolve(described_class, obj: epic, ctx: { current_user: current_user }) }

    context 'without sufficient rights' do
      let_it_be(:current_user) { other_user }
      let_it_be(:event) { create(:event, :created, project: project1, target: issue, author: user) }

      it { is_expected.to be_nil }
    end

    context 'when there has been no event created' do
      let_it_be(:current_user) { other_user }

      it { is_expected.to be_nil }
    end

    context 'when there is no signed in user' do
      let_it_be(:current_user) { nil }

      it { is_expected.to be_nil }
    end

    context 'with sufficient rights' do
      context 'when last event was an issue creation' do
        let_it_be(:issue_creation_event) do
          create(:event, :created, project: project1, target: issue, author: user)
        end

        it { is_expected.to eq(project1) }
      end

      context 'when last event was not an issue creation' do
        let_it_be(:issue_closed_event) do
          create(:event, :closed, project: project1, target: issue, author: user)
        end

        it { is_expected.to be_nil }
      end

      context 'when there are multiple events on different projects' do
        let_it_be(:issue_creation_event) do
          create(:event, :created, project: project2, target: issue2, author: user)
        end

        let_it_be(:last_issue_creation_event) do
          create(:event, :created, project: project1, target: issue, author: user)
        end

        it { is_expected.to eq(project1) }
      end

      context 'when project is outside of the group hierarchy' do
        let_it_be(:issue_creation_outside_hierarchy_event) do
          create(:event, :created, project: project_outside_hierarchy, target: issue_outside_hierarchy, author: user)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
