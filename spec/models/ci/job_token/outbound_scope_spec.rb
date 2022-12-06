# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::OutboundScope, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:source_project) { create(:project, ci_outbound_job_token_scope_enabled: true) }

  let(:scope) { described_class.new(source_project) }

  describe '#all_projects' do
    subject(:all_projects) { scope.all_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(all_projects).to contain_exactly(source_project)
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with scoped projects'

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(source_project, outbound_scoped_project)
      end
    end
  end

  describe '#includes?' do
    subject { scope.includes?(includes_project) }

    context 'without scoped projects' do
      context 'when self referential' do
        let(:includes_project) { source_project }

        it { is_expected.to be_truthy }
      end
    end

    context 'with scoped projects' do
      include_context 'with scoped projects'

      where(:includes_project, :result) do
        ref(:source_project)            | true
        ref(:inbound_scoped_project)    | false
        ref(:outbound_scoped_project)   | true
        ref(:unscoped_project1)         | false
        ref(:unscoped_project2)         | false
      end

      with_them do
        it { is_expected.to eq(result) }
      end

      context 'when project scope setting is disabled' do
        before do
          source_project.ci_outbound_job_token_scope_enabled = false
        end

        where(:includes_project, :result) do
          ref(:source_project)            | true
          ref(:inbound_scoped_project)    | true
          ref(:outbound_scoped_project)   | true
          ref(:unscoped_project1)         | true
          ref(:unscoped_project2)         | true
        end

        with_them do
          it 'considers any project as part of the scope' do
            is_expected.to eq(result)
          end
        end
      end
    end
  end
end
