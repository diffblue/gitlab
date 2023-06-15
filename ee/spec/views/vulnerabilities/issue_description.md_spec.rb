# frozen_string_literal: true

require "spec_helper"

RSpec.describe "vulnerabilities/issue_description.md.erb", type: :view, feature_category: :vulnerability_management do
  let(:finding) { build_stubbed(:vulnerabilities_finding, identifiers: identifiers, scan: scan) }
  let(:identifier) { build_stubbed(:vulnerabilities_identifier, project: project) }
  let(:project) { build_stubbed(:project, :repository) }
  let(:vulnerability_presenter) { VulnerabilityPresenter.new(vulnerability) }
  let(:vulnerability) do
    build_stubbed(
      :vulnerability,
      project: project,
      findings: [finding],
      description: vulnerability_description,
      severity: severity
    )
  end

  let(:vulnerability_description) { "Vulnerability Description" }
  let(:severity) { :high }
  let(:identifiers) { [identifier] }
  let(:scan) do
    { type: 'sast', status: 'success', start_time: 'placeholder', end_time: 'placeholder' }
  end

  before do
    Gitlab::CurrentSettings.default_branch_name = 'main'
    render(
      template: "vulnerabilities/issue_description",
      formats: :md,
      locals: { vulnerability: vulnerability_presenter }
    )
  end

  it 'renders markdown suitable for creating an issue description' do
    expect(rendered).to eq(
      <<~DESC
        Issue created from vulnerability #{link_to(vulnerability.id, vulnerability_url(vulnerability))}

        ### Description:

        Vulnerability Description

        * Severity: high
        * Location: [#{vulnerability_presenter.location_text}](#{vulnerability_presenter.location_link})

        #### Evidence

        * Method: `GET`
        * URL: http://goat:8080/WebGoat/logout

        ##### Request:

        ```
        Accept : */*
        ```

        ##### Response:

        ```
        Content-Length : 0
        ```

        ### Solution:

        GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.

        ### Identifiers:

        * [CVE-2018-1234](http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234)

        ### Links:

        * [Cipher does not check for integrity first?](https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first)

        ### Scanner:

        * Name: Find Security Bugs
        * Type: sast
        * Status: success
        * Start Time: placeholder
        * End Time: placeholder

        /confidential
      DESC
    )
  end

  context 'when a description is absent on the Vulnerability' do
    let(:vulnerability_description) { nil }

    it 'renders the Finding description' do
      expect(markdown_section("Description")).to start_with(vulnerability.finding.description)
    end
  end

  context 'when severity is absent' do
    let(:severity) { nil }

    it 'does not render the Severity section' do
      expect(rendered).not_to include('* Severity')
    end
  end

  context 'when identifiers are absent' do
    let(:identifiers) { [] }

    it 'does not render the Identifiers section' do
      expect(rendered).not_to include('### Identifiers')
    end
  end

  context 'when scan is absent' do
    let(:scan) { nil }

    it 'renders the scanner name only' do
      expect(markdown_section("Scanner")).to start_with("* Name: Find Security Bugs")
      expect(markdown_section("Scanner")).not_to include("* Type:")
      expect(markdown_section("Scanner")).not_to include("* Status:")
      expect(markdown_section("Scanner")).not_to include("* Start Time:")
      expect(markdown_section("Scanner")).not_to include("* End Time:")
    end
  end

  # Returns the content of a markdown section from the rendered view.  For example, given
  # this content:
  #
  #   ### Foo:
  #
  #   Foo content here
  #
  #   ### Bar:
  #
  #   Bar content here
  #
  # then:
  #
  #   markdown_section('Foo')
  #   => "Foo content here"
  #
  def markdown_section(section_name)
    sections_hash.fetch(section_name)
  end

  def sections_hash
    @sections_hash ||= rendered.split(/^#+ /).to_h { |s| s.split(':', 2).map(&:strip) }
  end
end
