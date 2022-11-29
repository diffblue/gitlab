# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::Routing do
  let(:proxified_class) { Issue }
  let(:included_class) { Elastic::Latest::ApplicationClassProxy }
  let(:project_ids) { [1, 2, 3] }
  let(:project_routing) { 'project_1,project_2,project_3' }

  subject { included_class.new(proxified_class) }

  describe '#search' do
    it 'calls routing_options with empty hash' do
      expect(subject).to receive(:routing_options).and_return({})

      subject.search('q')
    end

    it 'calls routing_options with correct routing' do
      expect(subject).to receive(:routing_options).and_return({ routing: project_routing })

      subject.search('q', project_ids: project_ids)
    end
  end

  describe '#routing_options' do
    it 'returns correct options for project_id' do
      expect(subject.routing_options({ project_id: 1 })).to eq({ routing: 'project_1' })
    end

    it 'returns correct options for repository_id' do
      expect(subject.routing_options({ repository_id: 1 })).to eq({ routing: 'project_1' })
    end

    it 'returns correct options for project_ids' do
      expect(subject.routing_options({ project_ids: project_ids })).to eq({ routing: project_routing })
    end

    it 'returns empty hash when provided an empty array' do
      expect(subject.routing_options({ project_ids: [] })).to eq({})
    end

    it 'returns empty hash when provided :any to project_ids' do
      expect(subject.routing_options({ project_ids: :any })).to eq({})
    end

    it 'returns empty hash when public projects flag is passed' do
      expect(subject.routing_options({ project_ids: project_ids, public_and_internal_projects: true })).to eq({})
    end

    it 'returns empty hash when routing_disabled flag is passed' do
      expect(subject.routing_options(routing_disabled: true)).to eq({})
    end

    it 'uses project_ids rather than repository_id when both are supplied' do
      options = { project_ids: project_ids, repository_id: 'wiki_5' }

      expect(subject.routing_options(options)).to eq({ routing: project_routing })
    end

    it 'returns empty hash when there are too many project_ids' do
      max_count = included_class::ES_ROUTING_MAX_COUNT

      expect(subject.routing_options({ project_ids: 1.upto(max_count + 1).to_a })).to eq({})
    end
  end
end
