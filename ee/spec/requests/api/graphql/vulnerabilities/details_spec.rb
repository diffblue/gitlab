# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.details', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

  let_it_be(:fields) do
    <<~QUERY
      details {
        __typename
        ... on VulnerabilityDetailBoolean {
          description
          fieldName
          name
          value
        }
        ... on VulnerabilityDetailCode {
          fieldName
          lang
          name
          value
        }
        ... on VulnerabilityDetailCommit {
          description
          fieldName
          name
          value
        }
        ... on VulnerabilityDetailDiff {
          after
          before
          description
          fieldName
          name
        }
        ... on VulnerabilityDetailFileLocation {
          description
          fieldName
          fileName
          lineEnd
          lineStart
          name
        }
        ... on VulnerabilityDetailInt {
          description
          fieldName
          name
          value
        }
        ... on VulnerabilityDetailMarkdown {
          description
          fieldName
          name
          value
        }
        ... on VulnerabilityDetailModuleLocation {
          description
          fieldName
          moduleName
          name
          offset
        }
        ... on VulnerabilityDetailText {
          description
          fieldName
          name
          value
        }
        ... on VulnerabilityDetailUrl {
          description
          fieldName
          href
          name
          text
        }
        ... on VulnerabilityDetailTable {
          description
          fieldName
          name
          headers {
            __typename
            ... on VulnerabilityDetailBoolean {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailCode {
              fieldName
              lang
              name
              value
            }
            ... on VulnerabilityDetailCommit {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailDiff {
              after
              before
              description
              fieldName
              name
            }
            ... on VulnerabilityDetailFileLocation {
              description
              fieldName
              fileName
              lineEnd
              lineStart
              name
            }
            ... on VulnerabilityDetailInt {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailMarkdown {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailModuleLocation {
              description
              fieldName
              moduleName
              name
              offset
            }
            ... on VulnerabilityDetailText {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailUrl {
              description
              fieldName
              href
              name
              text
            }
          }
          rows {
            __typename
            ... on VulnerabilityDetailBoolean {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailCode {
              fieldName
              lang
              name
              value
            }
            ... on VulnerabilityDetailCommit {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailDiff {
              after
              before
              description
              fieldName
              name
            }
            ... on VulnerabilityDetailFileLocation {
              description
              fieldName
              fileName
              lineEnd
              lineStart
              name
            }
            ... on VulnerabilityDetailInt {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailMarkdown {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailModuleLocation {
              description
              fieldName
              moduleName
              name
              offset
            }
            ... on VulnerabilityDetailText {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailUrl {
              description
              fieldName
              href
              name
              text
            }
          }
        }
        ... on VulnerabilityDetailList {
          description
          fieldName
          items {
            __typename
            ... on VulnerabilityDetailBoolean {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailCode {
              fieldName
              lang
              name
              value
            }
            ... on VulnerabilityDetailCommit {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailDiff {
              after
              before
              description
              fieldName
              name
            }
            ... on VulnerabilityDetailFileLocation {
              description
              fieldName
              fileName
              lineEnd
              lineStart
              name
            }
            ... on VulnerabilityDetailInt {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailMarkdown {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailModuleLocation {
              description
              fieldName
              moduleName
              name
              offset
            }
            ... on VulnerabilityDetailText {
              description
              fieldName
              name
              value
            }
            ... on VulnerabilityDetailUrl {
              description
              fieldName
              href
              name
              text
            }
          }
          name
        }
      }
    QUERY
  end

  let_it_be(:query) do
    graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, fields))
  end

  let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: :container_scanning) }

  let_it_be(:finding) do
    create(
      :vulnerabilities_finding,
      :with_details,
      vulnerability: vulnerability
    )
  end

  subject { graphql_data.dig('vulnerabilities', 'nodes') }

  before do
    project.add_developer(user)
    stub_licensed_features(security_dashboard: true)

    post_graphql(query, current_user: user)
  end

  let(:expected_details) do
    [
      {
        "__typename" => "VulnerabilityDetailUrl",
        "description" => nil,
        "fieldName" => "url",
        "href" => "https://gitlab.com",
        "name" => "GitLab URL",
        "text" => "URL to GitLab.com"
      },
      {
        "__typename" => "VulnerabilityDetailCode",
        "fieldName" => "code",
        "lang" => "javascript",
        "name" => "Truthy Code",
        "value" => "function isTrue(value) { value ? true : false }"
      },
      {
        "__typename" => "VulnerabilityDetailDiff",
        "after" => "Hello there\nHello Wooorld\nanew line\nhello again\nhello again",
        "before" => "Hello there\nHello world\nhello again",
        "description" => "How the data was modified",
        "fieldName" => "diff",
        "name" => "Modified data"
      },
      {
        "__typename" => "VulnerabilityDetailText",
        "description" => nil,
        "fieldName" => "text",
        "name" => "Text with more info",
        "value" => "More info about this vulnerability"
      },
      {
        "__typename" => "VulnerabilityDetailList",
        "description" => "The list of URLs in this report",
        "fieldName" => "urls",
        "items" => [
          {
            "__typename" => "VulnerabilityDetailUrl",
            "description" => nil,
            "fieldName" => nil,
            "href" => "https://gitlab.com",
            "name" => nil,
            "text" => nil
          },
          {
            "__typename" => "VulnerabilityDetailUrl",
            "description" => nil,
            "fieldName" => nil,
            "href" => "https://gitlab.com",
            "name" => nil,
            "text" => nil
          },
          {
            "__typename" => "VulnerabilityDetailUrl",
            "description" => nil,
            "fieldName" => nil,
            "href" => "https://gitlab.com",
            "name" => nil,
            "text" => nil
          }
        ],
        "name" => "URLs"
      },
      {
        "__typename" => "VulnerabilityDetailCommit",
        "description" => "Commit where the vulnerability was identified",
        "fieldName" => "commit",
        "name" => "The Commit",
        "value" => "41df7b7eb3be2b5be2c406c2f6d28cd6631eeb19"
      },
      {
        "__typename" => "VulnerabilityDetailFileLocation",
        "description" => "The first location",
        "fieldName" => "location1",
        "fileName" => "new_file.c",
        "lineEnd" => 6,
        "lineStart" => 5,
        "name" => "Location 1"
      },
      {
        "__typename" => "VulnerabilityDetailMarkdown",
        "description" => "GFM-flavored markdown",
        "fieldName" => "marked_up",
        "name" => "Marked Data",
        "value" => "Here is markdown `inline code` #1 [test](gitlab.com)\n\n![GitLab Logo](https://about.gitlab.com/images/press/logo/preview/gitlab-logo-white-preview.png)"
      },
      {
        "__typename" => "VulnerabilityDetailCode",
        "fieldName" => "code_block",
        "lang" => nil,
        "name" => "Code Block",
        "value" => "Here\nis\ncode"
      },
      {
        "__typename" => "VulnerabilityDetailList",
        "description" => nil,
        "fieldName" => "named_list",
        "items" => [
          {
            "__typename" => "VulnerabilityDetailText",
            "description" => "The description for field 1",
            "fieldName" => "field1",
            "name" => "Field 1",
            "value" => "Text"
          },
          {
            "__typename" => "VulnerabilityDetailText",
            "description" => "The description for field 2",
            "fieldName" => "field2",
            "name" => "Field 2",
            "value" => "Text"
          },
          {
            "__typename" => "VulnerabilityDetailList"
          }
        ],
        "name" => "A Named List"
      },
      {
        "__typename" => "VulnerabilityDetailTable",
        "description" => nil,
        "fieldName" => "table_data",
        "name" => "Registers",
        "headers" => [],
        "rows" => [
          {
            "__typename" => "VulnerabilityDetailInt",
            "description" => nil,
            "fieldName" => "{\"type\"=>\"text\", \"value\"=>\"eax\"}",
            "name" => nil,
            "value" => 1336
          },
          {
            "__typename" => "VulnerabilityDetailInt",
            "description" => nil,
            "fieldName" => "{\"type\"=>\"value\", \"value\"=>\"ebx\"}",
            "name" => nil,
            "value" => 1337
          },
          {
            "__typename" => "VulnerabilityDetailInt",
            "description" => nil,
            "fieldName" => "{\"type\"=>\"text\", \"value\"=>\"ecx\"}",
            "name" => nil,
            "value" => 1338
          },
          {
            "__typename" => "VulnerabilityDetailInt",
            "description" => nil,
            "fieldName" => "{\"type\"=>\"text\", \"value\"=>\"edx\"}",
            "name" => nil,
            "value" => 1339
          }
        ]
      },
      {
        "__typename" => "VulnerabilityDetailText",
        "description" => "The actual description of the description",
        "fieldName" => "description",
        "name" => "Description",
        "value" => "Text value"
      },
      {
        "__typename" => "VulnerabilityDetailList",
        "description" => nil,
        "fieldName" => "stack_trace",
        "items" => [
          {
            "__typename" => "VulnerabilityDetailModuleLocation",
            "description" => nil,
            "fieldName" => nil,
            "moduleName" => "compiled_binary",
            "name" => nil,
            "offset" => 100
          },
          {
            "__typename" => "VulnerabilityDetailModuleLocation",
            "description" => nil,
            "fieldName" => nil,
            "moduleName" => "compiled_binary",
            "name" => nil,
            "offset" => 500
          },
          {
            "__typename" => "VulnerabilityDetailModuleLocation",
            "description" => nil,
            "fieldName" => nil,
            "moduleName" => "compiled_binary",
            "name" => nil,
            "offset" => 700
          },
          {
            "__typename" => "VulnerabilityDetailModuleLocation",
            "description" => nil,
            "fieldName" => nil,
            "moduleName" => "compiled_binary",
            "name" => nil,
            "offset" => 1000
          }
        ],
        "name" => "Stack Trace"
      },
      {
        "__typename" => "VulnerabilityDetailModuleLocation",
        "description" => "The first location",
        "fieldName" => "module_location1",
        "moduleName" => "gitlab.h",
        "name" => "Module Location 1",
        "offset" => 100
      }
    ]
  end

  it 'returns a vulnerability details' do
    expect(subject.first['details']).to eq(expected_details)
  end
end
