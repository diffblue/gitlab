# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Private Project Snippets Access", feature_category: :source_code_management do
  include AccessMatchers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:private_snippet) { create(:project_snippet, :private, project: project, author: project.first_owner) }

  describe "GET /:project_path/snippets" do
    subject { project_snippets_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/snippets/new" do
    subject { new_project_snippet_path(project) }

    it { is_expected.to be_denied_for(:auditor) }
  end

  describe "GET /:project_path/snippets/:id for a private snippet" do
    subject { project_snippet_path(project, private_snippet) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/snippets/:id/raw for a private snippet" do
    subject { raw_project_snippet_path(project, private_snippet) }

    it { is_expected.to be_allowed_for(:auditor) }
  end
end
