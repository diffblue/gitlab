# frozen_string_literal: true

RSpec.shared_examples 'iteration board list' do
  before do
    stub_licensed_features(board_iteration_lists: true)
  end

  context 'when iteration_id is sent' do
    it 'returns 400 if iteration is not found' do
      other_iteration = create(:iteration)
      post api(url, user), params: { iteration_id: other_iteration.id }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response.dig('message', 'error')).to eq('Iteration not found')
    end

    it 'returns 400 if not licensed' do
      stub_licensed_features(board_iteration_lists: false)

      post api(url, user), params: { iteration_id: iteration.id }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response.dig('message', 'error'))
          .to eq('Iteration lists not available with your current license')
    end

    it 'creates an iteration list if iteration is found' do
      post api(url, user), params: { iteration_id: iteration.id }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response.dig('iteration', 'id')).to eq(iteration.id)
    end
  end
end
