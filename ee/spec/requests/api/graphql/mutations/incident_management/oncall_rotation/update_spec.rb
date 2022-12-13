# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Incident Management on-call shifts', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:participant) { create(:incident_management_oncall_participant, :with_developer_access) }
  let_it_be(:rotation) { participant.rotation }
  let_it_be(:schedule) { rotation.schedule }
  let_it_be(:project) { rotation.project }
  let_it_be(:current_user) { participant.user }

  let(:mutation) do
    graphql_mutation(:oncall_rotation_update, update_params) do
      <<-QL.strip_heredoc
        clientMutationId
        errors
        oncallRotation {
          id
          name
          startsAt
          length
          lengthUnit
          activePeriod {
           startTime
           endTime
          }
          participants {
            nodes {
              user {
                username
              }
              colorWeight
              colorPalette
            }
          }
        }
      QL
    end
  end

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_maintainer(current_user)
  end

  subject(:resolve) { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:oncall_rotation_update)
  end

  context 'updating name only' do
    let(:params) { { name: 'Test rotation mutation' } }

    it 'updates the rotation' do
      resolve

      expect(mutation_response['errors']).to be_empty

      oncall_rotation_response = mutation_response['oncallRotation']
      expect(oncall_rotation_response['name']).to eq(params[:name])
    end
  end

  context 'removing participants' do
    let(:params) { { participants: [] } }

    it 'updates the rotation and removes participants' do
      resolve

      expect(mutation_response['errors']).to be_empty

      oncall_rotation_response = mutation_response['oncallRotation']
      expect(oncall_rotation_response['participants']['nodes']).to eq([])

      expect(rotation.participants.removed.reload).not_to be_empty
      expect(rotation.participants.not_removed.reload).to be_empty
    end
  end

  context 'adding participants' do
    let(:new_user) { create(:user) }

    before do
      project.add_reporter(new_user)
    end

    let(:params) { { participants: [*existing_participant_params, participant_params(new_user)] } }

    it 'updates the rotation and adds participants' do
      resolve

      expect(mutation_response['errors']).to be_empty

      oncall_rotation_response = mutation_response['oncallRotation']
      response_participants = oncall_rotation_response['participants']['nodes']
      expect(response_participants.size).to eq(2)

      new_user_participant = response_participants.detect { |h| h.dig('user', 'username') == new_user.username }
      expect(new_user_participant['colorPalette']).to eq('blue')
      expect(new_user_participant['colorWeight']).to eq('500')

      expect(rotation.participants.removed.reload).to be_empty
      expect(rotation.participants.not_removed.reload.size).to eq(2)
    end
  end

  context 'errors' do
    context 'user cannot be found' do
      let(:params) { { participants: [{ username: 'unknown' }] } }

      it 'raises an error' do
        resolve

        expect(json_response['errors'][0]['message']).to eq("A provided username couldn't be matched to a user")
      end
    end
  end

  def update_params
    { id: rotation.to_global_id.uri }.merge(params)
  end

  def participant_params(user)
    participant = build(:incident_management_oncall_participant, user: user)

    {
      username: participant.user.username,
      colorWeight: 'WEIGHT_500',
      colorPalette: 'BLUE'
    }
  end

  def existing_participant_params
    rotation.participants.map do |participant|
      {
        username: participant.user.username,
        colorWeight: "WEIGHT_#{participant.color_weight}",
        colorPalette: participant.color_palette.upcase
      }
    end
  end
end
