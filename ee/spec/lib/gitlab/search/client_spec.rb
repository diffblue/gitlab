# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Search::Client do
  subject(:client) { described_class.new }

  it 'delegates to adapter', :aggregate_failures do
    described_class::DELEGATED_METHODS.each do |msg|
      expect(subject).to respond_to(msg)
      expect(subject.adapter).to receive(msg)
      subject.send(msg)
    end
  end
end
