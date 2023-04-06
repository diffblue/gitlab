# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryPresenter, feature_category: :source_code_management do
  let_it_be(:project) { build_stubbed(:project, :repository) }

  let(:repository) { project.repository }
  let(:presenter) { described_class.new(repository) }

  describe '#code_owners_path' do
    context 'when repository is empty' do
      it 'returns nil' do
        expect(presenter.code_owners_path(ref: 'master')).to be_nil
      end
    end

    context 'when repository is not empty' do
      before do
        allow(repository).to receive(:empty?).and_return(false)
      end

      context 'when there is no code owners file' do
        it 'returns nil' do
          expect(presenter.code_owners_path(ref: 'master')).to be_nil
        end
      end

      context 'when no ref is passed' do
        before do
          allow(repository).to receive(:code_owners_blob)
          allow(repository).to receive(:root_ref).and_return('root_ref')
          presenter.code_owners_path
        end

        it 'uses the root_ref' do
          expect(repository).to have_received(:code_owners_blob).with(ref: 'root_ref')
        end
      end

      context 'when a CODEOWNERS file exists' do
        let(:blob) { Gitlab::Git::Blob.new(path: 'docs/CODEOWNERS') }

        before do
          allow(repository)
            .to receive(:code_owners_blob).with(ref: 'with-codeowners')
            .and_return(blob)
        end

        it 'returns the correct path' do
          expect(presenter.code_owners_path(ref: 'with-codeowners'))
            .to eq("/#{project.full_path}/-/blob/with-codeowners/docs/CODEOWNERS")
        end
      end
    end
  end
end
