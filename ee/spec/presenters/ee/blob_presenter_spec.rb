# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobPresenter do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:blob) { project.repository.blob_at('HEAD', 'files/ruby/regex.rb') }

  subject(:presenter) { described_class.new(blob, current_user: user) }

  describe '#code_owners' do
    before do
      allow(Gitlab::CodeOwners).to receive(:for_blob).with(project, blob).and_return([user])
    end

    it { expect(presenter.code_owners).to match_array([user]) }
  end
end
