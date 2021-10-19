# frozen_string_literal: true

RSpec.shared_context 'valid urls with CRLF' do
  let(:valid_urls_with_CRLF) do
    [
      "http://example.com/pa\rth",
      "http://example.com/pa\nth",
      "http://example.com/pa\r\nth",
      "http://example.com/path?param=foo\r\nbar",
      "http://example.com/path?param=foo\rbar",
      "http://example.com/path?param=foo\nbar",
      "http://example.com/pa%0dth",
      "http://example.com/pa%0ath",
      "http://example.com/pa%0d%0th",
      "http://example.com/pa%0D%0Ath",
      "http://gitlab.com/path?param=foo%0Abar",
      "https://gitlab.com/path?param=foo%0Dbar",
      "http://example.org:1024/path?param=foo%0D%0Abar",
      "https://storage.googleapis.com/bucket/import_export_upload/import_file/57265/express.tar.gz?GoogleAccessId=hello@example.org&Signature=VBJkDX2MV4gi5wcARkvEmSVrNxRgbumVYcH6xw615IbIyT9kDw/+NXmHEqg7\n1mSTRypOjr2IkqaCgHJeyIF4mdOsII/XdgYomdV6zRSqrVmAD0BXg6jfCCCk&Expires=1634663304"
    ]
  end
end

RSpec.shared_context 'invalid urls' do
  let(:urls_with_CRLF) do
    [
      "git://example.com/pa\rth",
      "git://example.com/pa\nth",
      "git://example.com/pa\r\nth",
      "git://example.com/path?param=foo\r\nbar",
      "git://example.com/path?param=foo\rbar",
      "git://example.com/path?param=foo\nbar",
      "git://example.com/pa%0dth",
      "git://example.com/pa%0ath",
      "git://127.0a.0.1/pa%0d%0th",
      "git://example.com/pa%0D%0Ath",
      "git://gitlab.com/project%0Dpath",
      "git://gitlab.com/path?param=foo%0Abar"
    ]
  end
end
