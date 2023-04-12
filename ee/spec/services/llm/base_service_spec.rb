# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::BaseService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build_stubbed(:project, :public) }
  let_it_be(:resource) { build_stubbed(:issue, project: project) }
  let(:options) { {} }

  subject { described_class.new(user, resource, options) }

  it 'raises a NotImplementedError' do
    expect { subject.execute }.to raise_error(NotImplementedError)
  end
end
