# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence::SupportingMessage do
  it { is_expected.to belong_to(:evidence).class_name('Vulnerabilities::Finding::Evidence').inverse_of(:supporting_message).required }
  it { is_expected.to have_one(:request).class_name('Vulnerabilities::Finding::Evidence::Request').with_foreign_key('vulnerability_finding_evidence_supporting_message_id').inverse_of(:supporting_message) }
  it { is_expected.to have_one(:response).class_name('Vulnerabilities::Finding::Evidence::Response').with_foreign_key('vulnerability_finding_evidence_supporting_message_id').inverse_of(:supporting_message) }

  it { is_expected.to validate_length_of(:name).is_at_most(2048) }
end
