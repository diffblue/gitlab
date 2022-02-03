# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ImageAttachmentLinkFilter do
  include FilterSpecHelper

  let(:path) { '/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg' }

  def image(path, alt: nil)
    alt_tag = alt ? %Q{alt="#{alt}"} : ""

    %(<img src="#{path}" #{alt_tag} />)
  end

  it 'replaces the image with link to image src', :aggregate_failures do
    doc = filter(image(path))
    expect(doc.to_html).to match(%r{^<a[^>]*>#{path}</a>$})
    expect(doc.at_css('a')['href']).to eq(path)
  end

  it 'uses image alt as a link text', :aggregate_failures do
    doc = filter(image(path, alt: 'My image'))

    expect(doc.to_html).to match(%r{^<a[^>]*>My image</a>$})
    expect(doc.at_css('a')['href']).to eq(path)
  end

  it 'adds attachment icon class to the link' do
    doc = filter(image(path))

    expect(doc.at_css('a')['class']).to match(%r{with-attachment-icon})
  end

  it 'does not wrap a duplicate link' do
    doc = filter(%Q(<a href="/whatever">#{image(path)}</a>))

    expect(doc.to_html).to match(%r{^<a href="/whatever"><img[^>]*></a>$})
  end

  it 'works with external images' do
    external_path = 'https://i.imgur.com/DfssX9C.jpg'
    doc = filter(image(external_path))

    expect(doc.at_css('a')['href']).to eq(external_path)
  end

  it 'works with inline images' do
    doc = filter(%Q(<p>test #{image(path)} inline</p>))

    expect(doc.to_html).to match(%r{^<p>test <a[^>]*>#{path}</a> inline</p>$})
  end

  it 'keep the data-canonical-src' do
    data_canonical_src = "http://example.com/test.png"
    doc = filter(%Q(<img src="http://assets.example.com/6cd/4d7" data-canonical-src="#{data_canonical_src}" />))

    expect(doc.at_css('a')['data-canonical-src']).to eq(data_canonical_src)
  end
end
