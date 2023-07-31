# frozen_string_literal: true

module Gitlab
  module StatusPage
    # HTML filter that converts lazy loaded img nodes to standard HTML spec img nodes
    # We do not need to lazy load images on the Status Page
    module Filter
      class ImageFilter < HTML::Pipeline::Filter
        # Part of FileUploader::MARKDOWN_PATTERN but with a non-greedy file name matcher (?<file>.*) vs (?<file>.*?)
        NON_GREEDY_UPLOAD_FILE_PATH_PATTERN = %r{/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*)}

        CSS   = 'img'
        XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

        def call
          doc.xpath(XPATH).each do |image_node|
            image_node['class'] = 'gl-image'

            original_src = image_node.delete('data-src').value
            matches = NON_GREEDY_UPLOAD_FILE_PATH_PATTERN.match(original_src)
            next unless matches && matches[:secret] && matches[:file]

            change_image_path!(image_node, matches)
          end

          doc.to_html
        end

        def change_image_path!(image_node, matches)
          new_src = ::Gitlab::StatusPage::Storage.upload_path(
            context[:issue_iid],
            matches[:secret],
            matches[:file]
          )
          image_node['src'] = new_src
          image_node.parent['href'] = new_src
        end

        def validate
          raise ArgumentError unless context[:issue_iid]
        end
      end
    end
  end
end
