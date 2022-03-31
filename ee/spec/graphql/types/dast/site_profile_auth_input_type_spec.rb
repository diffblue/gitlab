# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Dast::SiteProfileAuthInputType do
  specify { expect(described_class.graphql_name).to eq('DastSiteProfileAuthInput') }

  it 'has the correct arguments' do
    expect(
      described_class.arguments.keys
    ).to match_array(%w[enabled url usernameField passwordField username password submitField])
  end
end
