# frozen_string_literal: true
require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210813134600_add_namespace_ancestry_to_issues_mapping.rb')

RSpec.describe AddNamespaceAncestryToIssuesMapping, :elastic, :sidekiq_inline do
  let(:version) { 20210813134600 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.new }

  before do
    allow(migration).to receive(:helper).and_return(helper)
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'when migration is already completed' do
      it 'does not modify data' do
        expect(helper).not_to receive(:update_mapping)

        subject
      end
    end

    context 'migration process' do
      before do
        allow(helper).to receive(:get_mapping).and_return({})
      end

      it 'updates the issues index mappings' do
        expect(helper).to receive(:update_mapping)

        subject
      end
    end
  end

  describe '.completed?' do
    context 'mapping has been updated' do
      specify { expect(migration).to be_completed }
    end

    context 'mapping has not been updated' do
      before do
        allow(helper).to receive(:get_mapping).and_return({})
      end

      specify { expect(migration).not_to be_completed }
    end
  end
end
