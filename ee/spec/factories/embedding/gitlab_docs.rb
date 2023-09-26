# frozen_string_literal: true

FactoryBot.define do
  factory :vertex_gitlab_documentation, class: 'Embedding::Vertex::GitlabDocumentation' do
    url { 'http://example.com/path/to/a/doc' }

    sequence(:metadata) do |n|
      {
        info: "Description for #{n}",
        source: "path/to/a/doc_#{n}.md",
        source_type: 'doc'
      }
    end

    version { 1 }
    content { 'Some text' }
    embedding { Array.new(768, 0.3) }
  end
end
