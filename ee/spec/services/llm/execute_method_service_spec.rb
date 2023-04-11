# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ExecuteMethodService, feature_category: :not_owned do # rubocop: disable RSpec/InvalidFeatureCategory
  let(:user) { create(:user) }
  let(:resource) { create(:issue) }
  let(:method) { :summarize_comments }
  let(:options) { {} }

  subject(:response) { described_class.new(user, resource, method, options) }

  it 'returns success' do
    expect(subject.execute).to be_success
  end
end
