# frozen_string_literal: true

RSpec.shared_examples 'epic mutation for user without access' do
  let(:other_user_author) { create(:user) }

  context 'when the user does not have access to the resource' do
    before do
      stub_licensed_features(epics: true)
      epic.update!(author: other_user_author)
    end

    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'even if author of the epic' do
      before do
        epic.update!(author: user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'even if assigned to the epic' do
      before do
        epic.assignees.push(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'even if maintainer of the project' do
      before do
        project.add_maintainer(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
