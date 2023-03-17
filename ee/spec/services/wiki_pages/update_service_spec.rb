# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::UpdateService, feature_category: :wiki do
  let(:user)    { create(:user) }
  let(:page)    { create(:wiki_page) }

  let(:opts) do
    {
      content: 'New content for wiki page',
      format: 'markdown',
      message: 'New wiki message'
    }
  end

  subject(:service) { described_class.new(container: container, current_user: user, params: opts) }

  describe '#execute' do
    let(:container) { create(:project) }

    it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { true }

      repository_updated_service = instance_double('::Geo::RepositoryUpdatedService')
      expect(::Geo::RepositoryUpdatedService).to receive(:new).with(container.wiki.repository) { repository_updated_service }
      expect(repository_updated_service).to receive(:execute)

      service.execute(page)
    end

    it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect(::Geo::RepositoryUpdatedService).not_to receive(:new)

      service.execute(page)
    end
  end

  it_behaves_like 'WikiPages::UpdateService#execute', :group do
    # TODO: Geo support for group wiki
    # https://gitlab.com/gitlab-org/gitlab/-/issues/208147
    it 'does not call Geo::RepositoryUpdatedService when container is group' do
      allow(Gitlab::Geo).to receive(:primary?) { true }

      expect(::Geo::RepositoryUpdatedService).not_to receive(:new)

      service.execute(page)
    end
  end
end
