# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveDuplicateCsFindings, :migration, schema: 20181228175414 do
  let(:namespaces) { table(:namespaces) }
  let(:notes) { table(:notes) }
  let(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:projects) { table(:projects) }
  let(:findings) { table(:vulnerability_occurrences) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }

  let(:identifiers) { table(:vulnerability_identifiers) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:issue_links) { table(:vulnerability_issue_links) }
  let(:finding_identifiers) { table(:vulnerability_occurrence_identifiers) }
  let(:users) { table(:users) }

  let!(:epic_1) { epics.create!(iid: 14532, title: 'from issue 1', group_id: group.id, author_id: user.id, title_html: 'any') }
  let!(:project) { projects.create!(id: 12058473, namespace_id: group.id, name: 'gitlab', path: 'gitlab') }
  let!(:user) { users.create!(id: 13, email: 'author@example.com', username: 'author', projects_limit: 10) }
  let!(:scanner) do
    scanners.create!(id: 6, project_id: project.id, external_id: 'trivy', name: 'Security Scanner')
  end

  it 'removes duplicate findings and vulnerabilities' do
    ids = [231411, 231412, 231413, 231500, 231600, 231700, 231800]

    fingerprints = %w(
      6c871440eb9f7618b9aef25e5246acddff6ed7a1
      9d1a47927875f1aee1e2b9f16c25a8ff7586f1a6
      d7da2cc109c18d890ab239e833524d451cc45246
      6c871440eb9f7618b9aef25e5246acddff6ed7a1
      9d1a47927875f1aee1e2b9f16c25a8ff7586f1a6
      d7da2cc109c18d890ab239e833524d451cc45246
      d7da2cc109c18d890ab239e833524d453cd45246
      475f029c81fa0a944bc825a44e02617867a4256d
    )

    expected_fingerprints = %w(
      6c871440eb9f7618b9aef25e5246acddff6ed7a1
      9d1a47927875f1aee1e2b9f16c25a8ff7586f1a6
      d7da2cc109c18d890ab239e833524d451cc45246
      d7da2cc109c18d890ab239e833524d453cd45246
      475f029c81fa0a944bc825a44e02617867a4256d
    )

    7.times.each { |x| identifiers.create!(vulnerability_identifer_params(x, project.id)) }
    7.times.each { vulnerabilities.create!(vulnerability_params(project.id, user.id)) }

    vulnerability_ids = vulnerabilities.all.ids

    3.times.each { |x| findings.create!(finding_params(x, project.id).merge({ id: ids[x], location_fingerprint: fingerprints[x], vulnerability_id: vulnerability_ids[x] })) }
    findings.create!(finding_params(0, project.id).merge({ id: ids[3], location_fingerprint: Gitlab::Database::ShaAttribute.new.serialize(fingerprints[3]).to_s, vulnerability_id: vulnerability_ids[3] }))
    findings.create!(finding_params(1, project.id).merge({ id: ids[4], location_fingerprint: Gitlab::Database::ShaAttribute.new.serialize(fingerprints[4]).to_s, vulnerability_id: vulnerability_ids[4] }))
    findings.create!(finding_params(2, project.id).merge({ id: ids[5], location_fingerprint: Gitlab::Database::ShaAttribute.new.serialize(fingerprints[5]).to_s, vulnerability_id: vulnerability_ids[5] }))
    findings.create!(finding_params(3, project.id).merge({ id: ids[6], location_fingerprint: Gitlab::Database::ShaAttribute.new.serialize(fingerprints[6]).to_s, vulnerability_id: vulnerability_ids[6] }))
    findings.create!(finding_params(3, project.id).merge({ id: 100000, location_fingerprint: Gitlab::Database::ShaAttribute.new.serialize(fingerprints[7]).to_s, vulnerability_id: nil }))

    7.times.each { |x| finding_identifiers.create!(occurrence_id: ids[x], identifier_id: x ) }
    1.upto(5).each { |x| issues.create!(description: '1234', state_id: 1, project_id: project.id, id: x) }

    notes.create!(project_id: project.id, noteable_id: vulnerability_ids[4], noteable_type: "Vulnerability", note: "test note", system: true)
    1.upto(5).each { |x| issue_links.create!(vulnerability_id: vulnerability_ids[x], issue_id: x ) }

    expect(finding_identifiers.all.count). to eq(7)
    expect(issue_links.all.count). to eq(5)

    described_class.new.perform(231411, 231413)

    expect(findings.ids).to match_array([100000, 231800, 231412, 231413, 231411])
    expect(findings.where(report_type: 2).count). to eq(5)
    expect(vulnerabilities.all.count). to eq(4)
    expect(notes.all.count). to eq(0)
    expect(finding_identifiers.all.count). to eq(4)
    expect(issue_links.all.count). to eq(2)

    location_fingerprints = findings.pluck(:location_fingerprint).flat_map { |x| Gitlab::Database::ShaAttribute.new.deserialize(x) }

    expect(location_fingerprints).to match_array(expected_fingerprints)
  end

  def vulnerability_identifer_params(id, project_id)
    {
      id: id,
      project_id: project_id,
      fingerprint: 'd432c2ad2953e8bd587a3a43b3ce309b5b0154c' + id.to_s,
      external_type: 'SECURITY_ID',
      external_id: 'SECURITY_0',
      name: 'SECURITY_IDENTIFIER 0'
    }
  end

  def vulnerability_params(project_id, user_id)
    {
      title: 'title',
      state: 1,
      confidence: 5,
      severity: 6,
      report_type: 2,
      project_id: project.id,
      author_id: user.id
    }
  end

  def finding_params(primary_identifier_id, project_id)
    uuid = SecureRandom.uuid
    {
      severity: 0,
      confidence: 5,
      report_type: 2,
      project_id: project_id,
      scanner_id: 6,
      primary_identifier_id: primary_identifier_id,
      project_fingerprint: SecureRandom.hex(20),
      location_fingerprint: Digest::SHA1.hexdigest(SecureRandom.hex(10)),
      uuid: uuid,
      name: "Vulnerability Finding #{uuid}",
      metadata_version: '1.3',
      raw_metadata: raw_metadata
    }
  end

  def raw_metadata
    { "description" => "The cipher does not provide data integrity update 1",
     "message" => "The cipher does not provide data integrity",
     "cve" => "818bf5dacb291e15d9e6dc3c5ac32178:CIPHER",
     "solution" => "GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.",
     "location" => { "file" => "maven/src/main/java/com/gitlab/security_products/tests/App.java", "start_line" => 29, "end_line" => 29, "class" => "com.gitlab.security_products.tests.App", "method" => "insecureCypher" },
     "links" => [{ "name" => "Cipher does not check for integrity first?", "url" => "https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first" }],
     "assets" => [{ "type" => "postman", "name" => "Test Postman Collection", "url" => "http://localhost/test.collection" }],
     "evidence" =>
      { "summary" => "Credit card detected",
       "request" => { "headers" => [{ "name" => "Accept", "value" => "*/*" }], "method" => "GET", "url" => "http://goat:8080/WebGoat/logout", "body" => nil },
       "response" => { "headers" => [{ "name" => "Content-Length", "value" => "0" }], "reason_phrase" => "OK", "status_code" => 200, "body" => nil },
       "source" => { "id" => "assert:Response Body Analysis", "name" => "Response Body Analysis", "url" => "htpp://hostname/documentation" },
       "supporting_messages" =>
        [{ "name" => "Origional", "request" => { "headers" => [{ "name" => "Accept", "value" => "*/*" }], "method" => "GET", "url" => "http://goat:8080/WebGoat/logout", "body" => "" } },
         { "name" => "Recorded",
          "request" => { "headers" => [{ "name" => "Accept", "value" => "*/*" }], "method" => "GET", "url" => "http://goat:8080/WebGoat/logout", "body" => "" },
          "response" => { "headers" => [{ "name" => "Content-Length", "value" => "0" }], "reason_phrase" => "OK", "status_code" => 200, "body" => "" } }] } }
  end
end
