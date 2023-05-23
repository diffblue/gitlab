# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::CodeSuggestionsAccessToken, feature_category: :code_suggestions do
  subject { described_class.new(token).as_json }

  let(:token) { Gitlab::CodeSuggestions::AccessToken.new }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(:access_token, :expires_in, :created_at)
  end
end
