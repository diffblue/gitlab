# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Allowlist do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:source_project) { create(:project) }

  let(:scope) { described_class.new(source_project, direction: direction) }

  let(:direction) { :outbound }

  describe '#projects' do
    subject(:all_projects) { scope.all_projects }

    context 'when no projects are added to the scope' do
      [:inbound, :outbound].each do |d|
        let(:direction) { d }

        it 'returns the project defining the scope' do
          expect(all_projects).to contain_exactly(source_project)
        end
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with scoped projects'

      where(:direction, :result) do
        :outbound | ref(:outbound_scoped_project)
        :inbound  | ref(:inbound_scoped_project)
      end

      with_them do
        it 'returns all projects that can be accessed from a given scope' do
          expect(subject).to contain_exactly(source_project, result)
        end
      end
    end
  end

  describe '#includes?' do
    subject { scope.includes?(includes_project) }

    context 'without projects' do
      context 'when project is self referential' do
        where(:direction, :result) do
          :outbound | true
          :inbound  | true
        end

        with_them do
          let(:includes_project) { source_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is not self referential' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | false
        end

        with_them do
          let(:includes_project) { build(:project) }

          it { is_expected.to be result }
        end
      end
    end

    context 'with scoped projects' do
      include_context 'with scoped projects'

      context 'when project is self referential' do
        where(:direction, :result) do
          :outbound | true
          :inbound  | true
        end

        with_them do
          let(:includes_project) { source_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is in inbound scope' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | true
        end

        with_them do
          let(:includes_project) { inbound_scoped_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is in outbound scope' do
        where(:direction, :result) do
          :outbound | true
          :inbound  | false
        end

        with_them do
          let(:includes_project) { outbound_scoped_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is linked to a different project' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | false
        end

        with_them do
          let(:includes_project) { unscoped_project1 }

          it { is_expected.to be result }
        end
      end

      context 'when project is unlinked to any project' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | false
        end

        with_them do
          let(:includes_project) { unscoped_project2 }

          it { is_expected.to be result }
        end
      end
    end
  end
end
