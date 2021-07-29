# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence::Request do
  it { is_expected.to belong_to(:evidence).class_name('Vulnerabilities::Finding::Evidence').inverse_of(:request) }
  it { is_expected.to belong_to(:supporting_message).class_name('Vulnerabilities::Finding::Evidence::SupportingMessage').inverse_of(:request) }
  it { is_expected.to have_many(:headers).class_name('Vulnerabilities::Finding::Evidence::Header').with_foreign_key('vulnerability_finding_evidence_request_id').inverse_of(:request) }

  it { is_expected.to validate_length_of(:method).is_at_most(32) }
  it { is_expected.to validate_length_of(:url).is_at_most(2048) }

  it_behaves_like 'body shared examples', :vulnerabilties_finding_evidence_request
end
