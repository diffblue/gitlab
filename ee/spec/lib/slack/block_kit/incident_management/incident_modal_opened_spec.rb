# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::BlockKit::IncidentManagement::IncidentModalOpened do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:response_url) { 'https://response.slack.com/id/123' }

  describe '#build' do
    subject(:payload) do
      described_class.new([project1, project2], response_url).build
    end

    it 'generates blocks for modal' do
      is_expected.to include({ type: 'modal', blocks: kind_of(Array), private_metadata: response_url })
    end

    it 'sets projects in the project selection' do
      project_list = payload[:blocks][1][:elements][0][:options]

      expect(project_list.first[:value]).to eq(project1.id.to_s)
      expect(project_list.last[:value]).to eq(project2.id.to_s)
    end

    it 'sets initial project option as the first project path' do
      initial_project = payload[:blocks][1][:elements][0][:initial_option]

      expect(initial_project[:value]).to eq(project1.id.to_s)
    end
  end
end
