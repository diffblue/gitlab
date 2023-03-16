# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticFullIndexWorker, feature_category: :global_search do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  it 'does nothing if ES disabled' do
    stub_ee_application_setting(elasticsearch_indexing: false)
    expect(Elastic::ProcessInitialBookkeepingService).not_to receive(:backfill_projects!)

    subject.perform(1, 2)
  end

  describe 'indexing' do
    let(:projects) { create_list(:project, 3) }

    it 'indexes projects in range' do
      projects.each do |project|
        expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
      end

      subject.perform(projects.first.id, projects.last.id)
    end
  end
end
