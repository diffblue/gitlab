# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DeletedProject, :geo, type: :model, feature_category: :geo_replication do
  include StubConfiguration

  subject { described_class.new(id: 1, name: 'sample', disk_path: 'root/sample', repository_storage: 'foo') }

  before do
    storages = {
      'foo' => { 'path' => 'tmp/tests/storage_foo' },
      'bar' => { 'path' => 'tmp/tests/storage_bar' }
    }

    stub_storage_settings(storages)
  end

  describe 'attributes' do
    it { is_expected.to respond_to(:id) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:disk_path) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:disk_path) }
  end

  describe 'attributes' do
    it { is_expected.to respond_to(:id) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:disk_path) }
  end

  describe '#full_path' do
    it 'is an alias for disk_path' do
      expect(subject.full_path).to eq 'root/sample'
    end
  end

  describe '#repository' do
    it 'returns a valid repository' do
      expect(subject.repository).to be_kind_of(Repository)
      expect(subject.repository.disk_path).to eq('root/sample')
    end
  end

  describe '#repository_storage' do
    it 'returns the initialized value when set' do
      expect(subject.repository_storage).to eq 'foo'
    end

    it 'picks storage from ApplicationSetting when value is not initialized' do
      stub_application_setting(pick_repository_storage: 'bar')

      subject = described_class.new(id: 1, name: 'sample', disk_path: 'root/sample', repository_storage: nil)

      expect(subject.repository_storage).to eq('bar')
    end
  end

  describe '#wiki' do
    it 'returns a valid wiki repository' do
      expect(subject.wiki).to be_kind_of(ProjectWiki)
      expect(subject.wiki.disk_path).to eq('root/sample.wiki')
    end
  end

  describe '#wiki_path' do
    it 'returns the wiki repository path on disk' do
      expect(subject.wiki_path).to eq('root/sample.wiki')
    end
  end
end
