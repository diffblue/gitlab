# frozen_string_literal: true

RSpec.shared_examples 'a search index' do
  let(:indexed_class) { described_class.indexed_class }
  let(:max_bucket_number) { described_class::MAX_BUCKET_NUMBER }
  let(:helper) { instance_double(::Gitlab::Elastic::Helper) }
  let(:index_path) { 'test-index-path' }

  before do
    allow(::Gitlab::Elastic::Helper).to receive(:default).and_return(helper)
    allow(helper).to receive(:target_index_name)
      .with(target: indexed_class.__elasticsearch__.index_name).and_return(index_path)
  end

  describe 'validations' do
    let(:index) { build(:search_index, type: described_class) }

    it 'is valid with proper attributes' do
      expect(index).to be_valid
    end

    it 'is invalid when missing #path' do
      index.path = nil
      expect(index).not_to be_valid
    end

    it 'is invalid when missing type' do
      index.type = nil
      expect(index).not_to be_valid
    end

    it 'is invalid when there is a duplicative index' do
      next_index = index.dup
      index.save!

      expect(next_index).not_to be_valid
      expect(next_index.errors.messages.fetch(:type)).to match_array([
        "violates unique constraint between [:type, :path]",
        "violates unique constraint between [:type, :bucket_number]"
      ])
    end

    describe '#bucket_number' do
      it 'is valid when nil' do
        index.bucket_number = nil
        expect(index).to be_valid
      end

      it 'is valid when given a number that is less than or equal to hashing modulo' do
        index.bucket_number = 0
        expect(index).to be_valid

        index.bucket_number = max_bucket_number
        expect(index).to be_valid
      end

      it 'is invalid when given a float' do
        index.bucket_number = 8675.309
        expect(index).to be_invalid
      end

      it 'is invalid when given a number that is greater than hashing modulo' do
        index.bucket_number = max_bucket_number + 1
        expect(index).to be_invalid
      end

      it 'is invalid when given a number that is less than zero' do
        index.bucket_number = -100
        expect(index).to be_invalid
      end
    end
  end

  describe '.next_index' do
    let(:index_one) { create(:search_index, type: described_class, bucket_number: 123) }
    let(:index_two) { create(:search_index, type: described_class, bucket_number: 300) }

    before do
      index_one
      index_two
    end

    it 'returns the first index ordered by bucket number' do
      expect(described_class.next_index(bucket_number: 124)).to eq(index_two)
      expect(described_class.next_index(bucket_number: 300)).to eq(index_two)
    end

    it 'returns nil if there are no indices with bucket_number greater than the one provided' do
      expect(described_class.next_index(bucket_number: 301)).to be_nil
      expect(described_class.next_index(bucket_number: 1_234)).to be_nil
    end
  end

  describe '.route' do
    context 'when there are not any indices' do
      it 'creates a default index' do
        expect(described_class).to receive(:create_default_index_with_max_bucket_number!)
        described_class.route(hash: 123)
      end
    end

    context 'when there are multiple indices in the DB' do
      let(:index_one) { create(:search_index, type: described_class, bucket_number: 123) }
      let(:index_two) { create(:search_index, type: described_class, bucket_number: 300) }
      let(:default_index) { create(:search_index, type: described_class, bucket_number: max_bucket_number) }

      before do
        index_one
        index_two
        default_index
      end

      it 'returns the correct index' do
        expect(described_class.route(hash: -10)).to eq(index_one)
        expect(described_class.route(hash: 0)).to eq(index_one)
        expect(described_class.route(hash: 90)).to eq(index_one)
        expect(described_class.route(hash: 123)).to eq(index_one)
        expect(described_class.route(hash: 124)).to eq(index_two)
        expect(described_class.route(hash: 300)).to eq(index_two)
        expect(described_class.route(hash: 301)).to eq(default_index)
        expect(described_class.route(hash: 1_000)).to eq(default_index)
        expect(described_class.route(hash: max_bucket_number)).to eq(default_index)
      end
    end

    context 'when given a bucket number that is outside maximum' do
      it 'raises an ArgumentError' do
        expect { described_class.route(hash: max_bucket_number + 1) }.to raise_error(
          ArgumentError, /hash must be less than or equal to max bucket number: #{max_bucket_number}/o
        )
      end
    end
  end

  describe '.create_default_index_with_max_bucket_number!' do
    it 'calls create! with correct arguments' do
      expect(described_class).to receive(:create!).with(
        path: index_path, bucket_number: max_bucket_number
      ).and_return :result

      expect(described_class.create_default_index_with_max_bucket_number!).to eq(:result)
    end

    it 'fetches index with matching attributes if there is a conflict' do
      expect(described_class).to receive(:create!).with(
        path: index_path, bucket_number: max_bucket_number
      ).and_raise ActiveRecord::RecordNotUnique

      expect(described_class).to receive(:find_by!).with(path: index_path, bucket_number: max_bucket_number)
        .and_return :other_result

      expect(described_class.create_default_index_with_max_bucket_number!).to eq(:other_result)
    end
  end
end
