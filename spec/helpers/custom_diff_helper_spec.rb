# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomDiffHelper do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:ipynb_blob) { repository.blob_at('f6b7a707', 'files/ipython/markdown-table.ipynb') }
  let(:blob) { repository.blob_at('HEAD', 'files/ruby/regex.rb') }

  describe "#preprocess_before_diff" do
    context 'for ipynb files' do
      it 'transforms the diff' do
        expect(CustomDiffHelper.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)).not_to include('cells')
      end

      it 'adds the blob to the list of transformed blobs' do
        CustomDiffHelper.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)

        expect(CustomDiffHelper.transformed_for_diff?(ipynb_blob)).to be_truthy
      end
    end

    context 'for other files' do
      it 'returns nil' do
        expect(CustomDiffHelper.preprocess_before_diff(blob.path, nil, blob)).to be_nil
      end

      it 'does not add the blob to the list of transformed blobs' do
        CustomDiffHelper.preprocess_before_diff(blob.path, nil, blob)

        expect(CustomDiffHelper.transformed_for_diff?(blob)).to be_falsey
      end
    end
  end

  describe "#transformed_blob_data" do
    it 'transforms blob data if file was processed' do
      CustomDiffHelper.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)

      expect(CustomDiffHelper.transformed_blob_data(ipynb_blob)).not_to include('cells')
    end

    it 'transforms blob data if file was not processed' do
      expect(CustomDiffHelper.transformed_blob_data(ipynb_blob)).to be_nil
    end
  end

  describe "#transformed_blob_language" do
    it 'is when file was preprocessed' do
      CustomDiffHelper.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)

      expect(CustomDiffHelper.transformed_blob_language(ipynb_blob)).to eq('md')
    end

    it 'is nil for .ipynb, but blob when it was not preprocessed' do
      expect(CustomDiffHelper.transformed_blob_language(ipynb_blob)).to be_nil
    end
  end
end
