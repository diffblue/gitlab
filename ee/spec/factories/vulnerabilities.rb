# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability do
    project
    author
    title { generate(:title) }
    title_html { "<h2>#{title}</h2>" }
    severity { :high }
    confidence { :medium }
    report_type { :sast }
    description { "Description of #{title}" }
    present_on_default_branch { true }

    trait :detected do
      state { Vulnerability.states[:detected] }
    end

    trait :resolved do
      state { Vulnerability.states[:resolved] }
      resolved_at { Time.current }
    end

    trait :dismissed do
      state { Vulnerability.states[:dismissed] }
      dismissed_at { Time.current }
    end

    trait :confirmed do
      state { Vulnerability.states[:confirmed] }
      confirmed_at { Time.current }
    end

    trait :critical_severity do
      severity { :critical }
    end

    trait :high_severity do
      severity { :high }
    end

    trait :medium_severity do
      severity { :medium }
    end

    trait :low_severity do
      severity { :low }
    end

    ::Enums::Vulnerability.severity_levels.keys.each do |severity_level|
      trait severity_level do
        severity { severity_level }
      end
    end

    ::Enums::Vulnerability.report_types.keys.each do |report_type|
      trait report_type do
        report_type { report_type }
      end
    end

    trait :with_read do
      after(:create) do |vulnerability|
        create(
          :vulnerability_read,
          vulnerability: vulnerability,
          project: vulnerability.project,
          report_type: vulnerability.report_type,
          severity: vulnerability.severity,
          state: vulnerability.state
        )
      end
    end

    trait :with_state_transition do
      transient do
        from_state { ::Enums::Vulnerability.vulnerability_states[:detected] }
        to_state { ::Enums::Vulnerability.vulnerability_states[:confirmed] }
      end

      after(:create) do |vulnerability, evaluator|
        create(
          :vulnerability_state_transition,
          vulnerability: vulnerability,
          from_state: evaluator.from_state,
          to_state: evaluator.to_state
        )
      end
    end

    trait :with_notes do
      transient do
        notes_count { 3 }
      end

      after(:create) do |vulnerability, evaluator|
        create_list(
          :note_on_vulnerability,
          evaluator.notes_count,
          noteable: vulnerability,
          project: vulnerability.project)
      end
    end

    trait :with_finding do
      after(:build) do |vulnerability|
        finding = build(
          :vulnerabilities_finding,
          :identifier,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project
        )

        vulnerability.findings = [finding]
      end
    end

    trait :with_cluster_image_scanning_finding do
      transient do
        agent_id { '46357' }
      end

      after(:build) do |vulnerability, evaluator|
        finding = build(
          :vulnerabilities_finding,
          :identifier,
          :with_cluster_image_scanning_scanning_metadata,
          agent_id: evaluator.agent_id,
          vulnerability: vulnerability,
          report_type: :cluster_image_scanning,
          project: vulnerability.project
        )

        vulnerability.findings = [finding]
      end
    end

    trait :with_remediation do
      after(:build) do |vulnerability|
        finding = build(
          :vulnerabilities_finding,
          :identifier,
          :with_remediation,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project
        )

        vulnerability.findings = [finding]
      end
    end

    trait :with_pipeline do
      after(:build) do |vulnerability|
        finding = build(
          :vulnerabilities_finding,
          :identifier,
          :with_pipeline,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project
        )

        vulnerability.findings = [finding]
      end
    end

    trait :with_findings do
      after(:build) do |vulnerability|
        findings_with_solution = build_list(
          :vulnerabilities_finding,
          2,
          :identifier,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project)
        findings_with_remediation = build_list(
          :vulnerabilities_finding,
          2,
          :identifier,
          :with_remediation,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project)
        vulnerability.findings = findings_with_solution + findings_with_remediation
      end
    end

    trait :with_issue_links do
      after(:create) do |vulnerability|
        create_list(:issue, 2, project: vulnerability.project).each do |issue|
          create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)
        end
      end
    end

    trait :with_merge_request_links do
      after(:create) do |vulnerability|
        merge_request = create(:merge_request, source_project: vulnerability.project)
        create(:vulnerabilities_merge_request_link, vulnerability: vulnerability, merge_request: merge_request)
      end
    end
  end
end
