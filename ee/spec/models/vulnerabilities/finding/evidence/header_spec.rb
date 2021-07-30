# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence::Header do
  it { is_expected.to belong_to(:request).class_name('Vulnerabilities::Finding::Evidence::Request').inverse_of(:headers).optional }
  it { is_expected.to belong_to(:response).class_name('Vulnerabilities::Finding::Evidence::Response').inverse_of(:headers).optional }

  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:value).is_at_most(8192) }
  it { is_expected.to validate_presence_of(:value) }
end
