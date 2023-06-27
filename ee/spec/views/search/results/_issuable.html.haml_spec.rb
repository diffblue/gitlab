# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "search/results/_issuable", feature_category: :global_search do
  let_it_be(:namespace) { build_stubbed(:namespace) }
  let_it_be(:project) { build_stubbed(:project, namespace: namespace, path: "foo/bar") }
  let_it_be(:author) { build_stubbed(:user) }
  let_it_be(:label) { build_stubbed(:label, project: project, title: 'test label') }
  let_it_be(:scoped_label) { build_stubbed(:label, project: project, title: 'foo::bar') }
  let_it_be(:issue) do
    build_stubbed(:issue,
      title: 'Test issue',
      project: project,
      author: author,
      description: 'Test description',
      labels: [label, scoped_label]
    )
  end

  before do
    assign(:project, project)
    assign(:issuable, issue)
    assign(:search_term, 'Test')
    assign(:search_highlight, true)
    assign(:scope, 'issues')

    assign(:issues, [issue])

    allow(namespace).to receive(:to_reference_base).and_return('namespace_reference')
    allow(issue).to receive(:to_reference).and_return("some_reference")
    allow(view).to receive(:presented_labels_sorted_by_title).and_return([label, scoped_label])
    allow(view).to receive(:project_issue_path).and_return("/some/path")
    allow(view).to receive(:issuable_path).and_return("/some/path")
    allow(label).to receive(:filter_path).and_return("/some/path")
    allow(label).to receive(:text_color_class).and_return("#FFFFFF")
    allow(scoped_label).to receive(:filter_path).and_return("/some/path")
    allow(scoped_label).to receive(:text_color_class).and_return("#FFFFFF")
  end

  context "when issuable has labels" do
    it "displays the label" do
      render partial: 'search/results/issuable', locals: { issuable: issue }

      expect(rendered).to have_selector('.gl-label.gl-label-scoped.gl-label-sm', text: 'foobar')
      expect(rendered).to have_selector('.gl-label.gl-label-sm', text: label.title)
    end
  end
end
