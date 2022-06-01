# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jira issues list', :js do
  include_context 'project integration activation'

  let_it_be(:per_page) { 20 }
  let_it_be(:public_url) { 'http://jira.foo.bar' }
  let_it_be(:api_url) { "#{public_url}/api" }
  let_it_be(:jira_project_key) { 'JIRA-GL1' }
  let_it_be(:jira_user) { 'JiraGitlabUser' }
  let_it_be(:timestamp) { Time.current }
  let_it_be(:jira) do
    create(
      :jira_integration,
      project: project,
      project_key: jira_project_key,
      deployment_type: 1,
      issues_enabled: true,
      api_url: api_url,
      url: public_url
    )
  end

  context 'when issues#index' do
    before do
      stub_licensed_features(jira_issues_integration: true)
    end

    it 'shows all three tabs' do
      with_issues 1 do
        within('div.issuable-list-container') do
          expect(page).to have_selector('li.nav-item', count: 3, wait: 0)
        end
      end
    end

    it 'has a button to create a new issue in Jira' do
      with_issues 1 do
        within('div.issuable-list-container') do
          link = page.find_link(href: /#{public_url}/, class: 'btn')
          expect(link.text).to match(/Create new issue in Jira/)
        end
      end
    end

    it 'shows the filtered search bar' do
      with_issues 10 do
        expect(page).to have_selector('div[data-testid="filtered-search-input"]')
      end
    end

    it 'paginates the list results' do
      number_of_issues = 35.0
      number_of_pages = (number_of_issues / per_page).ceil

      with_issues number_of_issues do |issues|
        expect(all_pages.size).to be(number_of_pages)
        all_pages.size.times do |page_num|
          navigate_to_page(page_num)

          offset = per_page * page_num

          aggregate_failures do
            within('ul.issuable-list') do
              issues[offset...per_page].each_with_index do |issue, idx|
                issuable_row = find("li#issuable_#{idx + offset}", wait: 0)
                expect(issuable_row.text).to include(jira_user)
                expect(issuable_row.text).to include(issue[:key])
                expect(issuable_row.text).to include(issue.dig(:fields, :summary))
                expect(issuable_row.text).to include(issue.dig(:fields, :status, :name))
                expect(issuable_row.text).to include(issue.dig(:fields, :labels, 0))
              end
            end
          end
        end
      end
    end
  end

  context 'when title or description contains HTML characters' do
    let(:html) { '<script>foobar</script>' }
    let(:escaped_html) { ERB::Util.html_escape(html) }
    let(:issue) { build_issue(1).deep_merge(fields: { summary: html }) }

    before do
      stub_licensed_features(jira_issues_integration: true)
    end

    it 'escapes the HTML on issues#index' do
      stub_issues([issue])

      visit project_integrations_jira_issues_path(project)

      expect(page).to have_text(html)
      expect(page).not_to have_css('script', text: 'foobar')
      expect(page.source).to include(escaped_html)
    end

    it 'escapes the HTML on issues#show' do
      issue.deep_merge!(
        fields: { comment: { comments: [] } },
        renderedFields: { description: html },
        duedate: Time.zone.now.to_s
      )

      stub_request(:get, /\A#{public_url}/)
        .to_return(headers: { 'Content-Type' => 'application/json' }, body: issue.to_json)

      visit project_integrations_jira_issue_path(project, 1)

      expect(page).to have_text(html)
      expect(page).not_to have_css('script', text: 'foobar')
      expect(page.source).to include(escaped_html)
    end
  end

  private

  def all_pages
    # the first and last navigation items
    # are Previous, and Next - ignore these.
    all('ul.pagination li.page-item')[1..-2]
  end

  def navigate_to_page(page)
    all_pages[page].click
  end

  def build_issues(count = 10)
    (0...count).to_a.map do |idx|
      build_issue(idx)
    end
  end

  def build_issue(idx)
    {
      id: idx,
      key: "#{jira_project_key}-#{idx}",
      fields: {
        summary: "Jira issue #{idx}",
        description: "Jira description #{idx}",
        created: (timestamp + idx).to_s,
        updated: (timestamp + idx).to_s,
        resolutiondate: nil,
        reporter: {
          name: jira_user,
          key: jira_user,
          emailAddress: "#{jira_user}@gitlab.com",
          displayName: jira_user,
          active: true,
          avatarUrls: { '48x48' => 'foo.jpg' }
        },
        labels: ["QA"],
        status: {
          description: "Status #{idx}",
          name: 'In Progress',
          statusCategory: {
            colorName: 'yellow',
            name: 'In Progress'
          }
        }
      }
    }
  end

  def with_issues(count)
    issues = build_issues count
    stub_issues issues
    visit project_integrations_jira_issues_path(project)
    yield issues
  end

  def stub_issues(issues)
    body = { startAt: 0, total: issues.size, maxResults: issues.size, issues: issues }
    stub_request(:get, /\A#{public_url}/)
      .to_return(headers: { 'Content-Type' => 'application/json' }, body: body.to_json)
  end
end
