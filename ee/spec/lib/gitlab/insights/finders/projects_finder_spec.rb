# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Finders::ProjectsFinder do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:project3) { create(:project) }

  subject(:projects) { described_class.new(projects_param).execute&.select(:id) }

  context 'when using ids' do
    let(:projects_param) { { only: [project1.id, project3.id] } }

    it { is_expected.to match_array([project1, project3]) }
  end

  context 'when using paths' do
    let(:projects_param) { { only: [project1.full_path, project2.full_path] } }

    it { is_expected.to match_array([project1, project2]) }
  end

  context 'when using mixed types' do
    let(:projects_param) { { only: [project1.full_path, project3.id] } }

    it { is_expected.to match_array([project1, project3]) }
  end

  context 'when using unknown references' do
    let(:projects_param) { { only: [:symbol, {}, project3.id] } }

    it { is_expected.to match_array([project3]) }
  end

  context 'when empty array is given' do
    let(:projects_param) { { only: [] } }

    it { is_expected.to eq(nil) }
  end
end
