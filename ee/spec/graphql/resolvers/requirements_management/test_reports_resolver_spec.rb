# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::RequirementsManagement::TestReportsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  context 'with a project' do
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:requirement) { create(:work_item, :requirement, project: project, state: :opened, created_at: 5.hours.ago) }
    let_it_be(:test_report1) { create(:test_report, requirement_issue: requirement, created_at: 3.hours.ago) }
    let_it_be(:test_report2) { create(:test_report, requirement_issue: requirement, created_at: 4.hours.ago) }

    before do
      stub_licensed_features(requirements: true)
      project.add_developer(current_user)
    end

    describe '#resolve' do
      it 'finds all test_reports' do
        expect(resolve_test_reports).to contain_exactly(test_report1, test_report2)
      end

      describe 'sorting' do
        context 'when sorting by created_at' do
          it 'sorts test reports ascending' do
            expect(resolve_test_reports(sort: 'created_asc')).to eq([test_report2, test_report1])
          end

          it 'sorts test reports descending' do
            expect(resolve_test_reports(sort: 'created_desc')).to eq([test_report1, test_report2])
          end
        end
      end
    end
  end

  def resolve_test_reports(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: requirement, args: args, ctx: context)
  end
end
