# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ImportCsvService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:file) { fixture_file_upload('spec/fixtures/csv_complex.csv') }
  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader)
  end

  describe '#execute' do
    subject { service.execute }

    it_behaves_like 'performs a spam check', true

    context 'when the user is an admin' do
      before do
        allow(user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it_behaves_like 'performs a spam check', false
    end

    context 'when the user is a paid user' do
      before do
        allow(user).to receive(:has_paid_namespace?).and_return(true)
      end

      it_behaves_like 'performs a spam check', false
    end
  end
end
