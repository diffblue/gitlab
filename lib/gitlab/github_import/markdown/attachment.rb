# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Markdown
      class Attachment
        class << self
          def from_markdown(markdown_text)
            url = extract_url_from_markdown(markdown_text)
            name = extract_name_from_markdown(markdown_text)
            new(name, url)
          end

          # img - An instance of `Nokogiri::XML::Element`
          def from_img_tag(img)
            new(img[:alt], img[:src])
          end

          private

          # in: "![image-icon](https://user-images.githubusercontent.com/..)"
          # out: https://user-images.githubusercontent.com/..
          def extract_url_from_markdown(text)
            text.match(%r{https://.*\)$}).to_a[0].chop
          end

          # in: "![image-icon](https://user-images.githubusercontent.com/..)"
          # out: image-icon
          def extract_name_from_markdown(text)
            name = text.match(%r{^!?\[.*\]}).to_a[0]
            name = name.chop # ![image-icon] => ![image-icon
            name.start_with?('!') ? name[2..] : name[1..]
          end
        end

        attr_reader :name, :url

        def initialize(name, url)
          @name = name
          @url = url
        end

        def inspect
          "Attachment { name: #{name}, url: #{url} }"
        end
      end
    end
  end
end
