# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20220512150000_pause_indexing_for_unsupported_es_versions.rb')

RSpec.describe PauseIndexingForUnsupportedEsVersions do
  let(:version) { 20220512150000 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.new }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
  end

  describe '.completed?' do
    subject { migration.completed? }

    it { is_expected.to be_truthy }
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'using an unsupported es version' do
      before do
        allow(helper).to receive(:supported_version?).and_return(false)
      end

      it 'pauses indexing' do
        expect { subject }.to change { Gitlab::CurrentSettings.elasticsearch_pause_indexing? }.from(false).to(true)
      end

      context 'indexing has already been paused' do
        before do
          stub_ee_application_setting(elasticsearch_pause_indexing: true)
        end

        it 'does nothing' do
          expect(Gitlab::CurrentSettings).not_to receive(:update!)

          subject
        end
      end
    end
  end
end
