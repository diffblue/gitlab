# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::EpicIssuesResolver do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project1) { create(:project, :public, group: group) }
  let_it_be(:project2) { create(:project, :private, group: group) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }
  let_it_be(:issue1) { create(:issue, project: project1) }
  let_it_be(:issue2) { create(:issue, project: project1, confidential: true) }
  let_it_be(:issue3) { create(:issue, project: project2) }
  let_it_be(:issue4) { create(:issue, project: project2) }
  let_it_be(:issue5) { create(:issue, project: project1) }
  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1, relative_position: 3) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic1, issue: issue2, relative_position: 2) }
  let_it_be(:epic_issue3) { create(:epic_issue, epic: epic2, issue: issue3, relative_position: 1) }
  let_it_be(:epic_issue4) { create(:epic_issue, epic: epic2, issue: issue4, relative_position: nil) }
  let_it_be(:epic_issue5) { create(:epic_issue, epic: epic1, issue: issue5, relative_position: nil) }

  let(:schema) do
    Class.new(GitlabSchema) do
      default_max_page_size 100
    end
  end

  before do
    group.add_developer(developer)
    stub_licensed_features(epics: true)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::EpicIssueType.connection_type)
  end

  describe '#resolve' do
    using RSpec::Parameterized::TableSyntax

    where(:epic, :user, :max_page_size, :has_next_page, :issues) do
      ref(:epic1) | ref(:developer) | 100 | false | lazy { [issue2, issue1, issue5] }
      ref(:epic1) | ref(:developer) | 2   | true  | lazy { [issue2, issue1] }
      ref(:epic1) | ref(:guest)     | 100 | false | lazy { [issue1, issue5] }
      ref(:epic2) | ref(:developer) | 100 | false | lazy { [issue3, issue4] }
      ref(:epic2) | ref(:guest)     | 100 | false | lazy { [] }
    end

    with_them do
      it 'returns only a page of issues user can read' do
        result = resolve_epic_issues(epic, user, max_page_size)

        expect(result.to_a).to eq issues
        expect(result.has_next_page).to eq has_next_page
      end
    end
  end

  def resolve_epic_issues(object, user, max_page_size)
    resolver = described_class
    opts = resolver.field_options
    allow(resolver).to receive(:field_options).and_return(opts.merge(max_page_size: max_page_size))

    force(resolve(resolver, obj: object, ctx: { current_user: user }))
  end
end
