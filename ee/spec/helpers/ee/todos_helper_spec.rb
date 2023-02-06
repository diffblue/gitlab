# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::TodosHelper do
  describe '#todo_types_options' do
    it 'includes options for an epic todo' do
      expect(helper.todo_types_options).to include(
        { id: 'Epic', text: 'Epic' }
      )
    end
  end

  describe '#todo_target_path' do
    context 'when target is vulnerability' do
      let(:vulnerability) { create(:vulnerability) }
      let(:todo) { create(:todo, target: vulnerability, project: vulnerability.project) }

      subject(:todo_target_path) { helper.todo_target_path(todo) }

      it { is_expected.to eq("/#{todo.project.full_path}/-/security/vulnerabilities/#{todo.target.id}") }
    end
  end

  describe '#todo_author_display?' do
    using RSpec::Parameterized::TableSyntax

    let!(:todo) { create(:todo) }

    subject { helper.todo_author_display?(todo) }

    where(:action, :result) do
      ::Todo::MERGE_TRAIN_REMOVED | false
      ::Todo::ASSIGNED            | true
    end

    with_them do
      before do
        todo.action = action
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#todo_target_state_pill' do
    subject { helper.todo_target_state_pill(todo) }

    shared_examples 'a rendered state pill' do |attr|
      it 'returns expected html' do
        aggregate_failures do
          expect(subject).to have_css(attr[:css])
          expect(subject).to have_content(attr[:state].capitalize)
        end
      end
    end

    shared_examples 'no state pill' do
      specify { expect(subject).to eq(nil) }
    end

    context 'in epic todo' do
      let(:todo) { create(:todo, target: create(:epic)) }

      it_behaves_like 'no state pill'

      context 'with closed epic' do
        before do
          todo.target.update!(state: 'closed')
        end

        it_behaves_like 'a rendered state pill', css: '.badge-info', state: 'closed'
      end
    end
  end

  describe '#show_todo_state?' do
    let(:closed_epic) { create(:epic, state: 'closed') }
    let(:todo) { create(:todo, target: closed_epic) }

    it 'returns true for a closed epic' do
      expect(helper.show_todo_state?(todo)).to eq(true)
    end
  end
end
