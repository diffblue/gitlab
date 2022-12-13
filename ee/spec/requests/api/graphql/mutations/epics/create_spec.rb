# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an Epic', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:attributes) do
    {
      title: 'title',
      description: 'some description',
      start_date_fixed: '2019-09-17',
      due_date_fixed: '2019-09-18',
      start_date_is_fixed: true,
      due_date_is_fixed: true,
      confidential: true,
      color: ::Gitlab::Color.of('#ff0000')
    }
  end

  let(:mutation) do
    params = { group_path: group.full_path }.merge(attributes)

    graphql_mutation(:create_epic, params)
  end

  def mutation_response
    graphql_mutation_response(:create_epic)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create epic' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Epic, :count)
    end
  end

  context 'when the user has permission' do
    before do
      group.add_reporter(current_user)
    end

    context 'when epics are disabled' do
      before do
        stub_licensed_features(epics: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['The resource that you are attempting to access does not '\
                 'exist or you don\'t have permission to perform this action']
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'creates the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        epic_hash = mutation_response['epic']
        expect(epic_hash['title']).to eq('title')
        expect(epic_hash['description']).to eq('some description')
        expect(epic_hash['startDateFixed']).to eq('2019-09-17')
        expect(epic_hash['startDateIsFixed']).to eq(true)
        expect(epic_hash['dueDateFixed']).to eq('2019-09-18')
        expect(epic_hash['dueDateIsFixed']).to eq(true)
        expect(epic_hash['confidential']).to eq(true)
        expect(epic_hash['color']).to be_color(attributes[:color])
        expect(epic_hash['textColor']).to be_color(attributes[:color].contrast)
      end

      context 'when using a named color' do
        before do
          attributes[:color] = 'red'
        end

        it 'sets the color correctly' do
          post_graphql_mutation(mutation, current_user: current_user)

          epic_hash = mutation_response['epic']

          expect(epic_hash['color']).to be_color(Gitlab::Color.of(attributes[:color]))
          expect(epic_hash['textColor']).to be_color(Gitlab::Color.of(attributes[:color]).contrast)
        end
      end

      context 'the color is invalid' do
        before do
          attributes[:color] = 'ne pas une couleur'
        end

        it 'reports a coercion error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect_graphql_errors_to_include(/Not a color/)
        end
      end

      context 'when there are ActiveRecord validation errors' do
        let(:attributes) { { title: '' } }

        it_behaves_like 'a mutation that returns errors in the response',
          errors: ["Title can't be blank"]

        it 'does not create the epic' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Epic, :count)
        end
      end

      context 'when the list of attributes is empty' do
        let(:attributes) { {} }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['The list of epic attributes is empty']

        it 'does not create the epic' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Epic, :count)
        end
      end
    end
  end
end
