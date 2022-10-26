# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::UserClassProxy do
  it 'is not implemented' do
    expect { described_class.new(any_args).elastic_search(any_args) }.to raise_error(NotImplementedError)
  end
end
