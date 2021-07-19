# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence::Response do
  it { is_expected.to belong_to(:evidence).class_name('Vulnerabilities::Finding::Evidence').inverse_of(:response) }
  it { is_expected.to belong_to(:supporting_message).class_name('Vulnerabilities::Finding::Evidence::SupportingMessage').inverse_of(:response) }
  it { is_expected.to have_many(:headers).class_name('Vulnerabilities::Finding::Evidence::Header').with_foreign_key('vulnerability_finding_evidence_response_id').inverse_of(:response) }

  it { is_expected.to validate_length_of(:reason_phrase).is_at_most(2048) }

  it_behaves_like 'body shared examples', :vulnerabilties_finding_evidence_response
end
