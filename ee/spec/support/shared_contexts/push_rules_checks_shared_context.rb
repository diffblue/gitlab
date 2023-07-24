# frozen_string_literal: true

RSpec.shared_context 'push rules checks context' do
  include_context 'change access checks context'

  let(:project) { create(:project, :public, :repository, push_rule: push_rule) }

  let(:new_commits) { project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51') }

  before do
    allow(project.repository).to receive(:new_commits).and_return(new_commits)
  end
end
