# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence do
  it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding').required }
  it { is_expected.to have_one(:request).class_name('Vulnerabilities::Finding::Evidence::Request').with_foreign_key('vulnerability_finding_evidence_id').inverse_of(:evidence) }
  it { is_expected.to have_one(:response).class_name('Vulnerabilities::Finding::Evidence::Response').with_foreign_key('vulnerability_finding_evidence_id').inverse_of(:evidence) }
  it { is_expected.to have_one(:supporting_message).class_name('Vulnerabilities::Finding::Evidence::SupportingMessage').with_foreign_key('vulnerability_finding_evidence_id').inverse_of(:evidence) }
  it { is_expected.to have_one(:source).class_name('Vulnerabilities::Finding::Evidence::Source').with_foreign_key('vulnerability_finding_evidence_id').inverse_of(:evidence) }
  it { is_expected.to have_many(:assets).class_name('Vulnerabilities::Finding::Evidence::Asset').with_foreign_key('vulnerability_finding_evidence_id').inverse_of(:evidence) }

  it { is_expected.to validate_length_of(:summary).is_at_most(8_000_000) }
end
