# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Parsers
        module Security
          module Common
            extend ::Gitlab::Utils::Override

            private

            override :report_data
            def report_data
              @report_data ||= parser.parse(json_data)
            end

            def parser
              ::Feature.enabled?(:use_introspect_parser, project) ? introspect_parser : ::Gitlab::Json
            end

            # New Oj parsers are not thread safe, therefore,
            # we need to initialize them for each thread.
            def introspect_parser
              Thread.current[:introspect_parser] ||= Oj::Introspect.new(filter: "remediations")
            end

            # map remediations to relevant vulnerabilities
            def collate_remediations
              return report_data["vulnerabilities"] || [] unless report_data["remediations"]

              report_data["vulnerabilities"].map do |vulnerability|
                remediation = fixes[vulnerability['id']] || fixes[vulnerability['cve']]
                vulnerability.merge("remediations" => [remediation])
              end
            end

            def fixes
              @fixes ||= report_data['remediations'].each_with_object({}) do |item, memo|
                item['fixes'].each do |fix|
                  id = fix['id'] || fix['cve']
                  memo[id] = item if id
                end
                memo
              end
            end

            def create_remediations(remediations_data)
              remediations_data.to_a.compact.map do |remediation_data|
                ::Gitlab::Ci::Reports::Security::Remediation.new(
                  remediation_data['summary'],
                  remediation_data['diff'],
                  **remediation_data.fetch(Oj::Introspect::KEY, {})
                )
              end
            end

            override :create_findings
            def create_findings
              collate_remediations.each do |finding|
                create_finding(finding, create_remediations(finding["remediations"]))
              end
            end
          end
        end
      end
    end
  end
end
