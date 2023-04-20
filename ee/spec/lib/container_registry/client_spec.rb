# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Client do
  let(:token) { '12345' }
  let(:options) { { token: token } }
  let(:client) { described_class.new("http://registry", options) }
  let(:base_headers) { { 'Authorization' => 'bearer 12345', 'User-Agent' => "GitLab/#{Gitlab::VERSION}" } }
  let(:push_blob_headers) do
    base_headers.merge({
      'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
      'Content-Length' => '3',
      'Content-Type' => 'application/octet-stream'
    })
  end

  let(:headers_with_accept_types) do
    base_headers.merge({
      'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json'
    })
  end

  let(:headers_with_accept_types_with_list) do
    base_headers.merge({
      'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.index.v1+json'
    })
  end

  describe '#push_blob' do
    it 'follows redirect and makes put query' do
      stub_request(:put, "http://registry/v2/group/test/blobs/uploads/abcd?digest=mytag")
        .with(headers: base_headers)
        .to_return(status: 200, body: '', headers: { 'Content-Length' => '5' })

      stub_request(:post, "http://registry/v2/group/test/blobs/uploads/")
        .with(headers: base_headers)
        .to_return(status: 200, body: '', headers: { 'Location' => 'http://registry/v2/group/test/blobs/uploads/abcd' })

      expect(client.push_blob('group/test', 'mytag', '', 5)).to eq(true)
    end

    it 'raises error if response status is not 200' do
      stub_request(:put, "http://registry/v2/group/test/blobs/uploads/abcd?digest=mytag")
        .with(headers: base_headers)
        .to_return(status: 404, body: "", headers: {})

      stub_request(:post, "http://registry/v2/group/test/blobs/uploads/")
        .with(headers: base_headers)
        .to_return(status: 200, body: "", headers: { 'Location' => 'http://registry/v2/group/test/blobs/uploads/abcd' })

      expect { client.push_blob('group/test', 'mytag', '', 32456) }
        .to raise_error(EE::ContainerRegistry::Client::Error)
    end
  end

  describe '#push_manifest' do
    let(:manifest) { 'manifest' }
    let(:manifest_type) { 'application/vnd.docker.distribution.manifest.v2+json' }
    let(:manifest_headers) do
      base_headers.merge({
        'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
        'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json'
      })
    end

    it 'PUT v2/:name/manifests/:tag' do
      stub_request(:put, "http://registry/v2/group/test/manifests/my-tag")
        .with(
          body: "manifest",
          headers: manifest_headers
        )
        .to_return(status: 200, body: "", headers: {})

      expect(client.push_manifest('group/test', 'my-tag', manifest, manifest_type)).to eq(true)
    end

    it 'raises error if response status is not 200' do
      stub_request(:put, "http://registry/v2/group/test/manifests/my-tag")
        .with(
          body: "manifest",
          headers: manifest_headers
        )
        .to_return(status: 404, body: "", headers: {})

      expect { client.push_manifest('group/test', 'my-tag', manifest, manifest_type) }
        .to raise_error(EE::ContainerRegistry::Client::Error)
    end
  end

  describe '#blob_exists?' do
    let(:digest) { 'digest' }

    it 'returns true' do
      stub_request(:head, "http://registry/v2/group/test/blobs/digest")
        .with(headers: headers_with_accept_types)
        .to_return(status: 200, body: "", headers: {})

      expect(client.blob_exists?('group/test', digest)).to eq(true)
    end

    it 'returns false' do
      stub_request(:head, "http://registry/v2/group/test/blobs/digest")
        .with(headers: headers_with_accept_types)
        .to_return(status: 404, body: "", headers: {})

      expect(client.blob_exists?('group/test', digest)).to eq(false)
    end
  end

  describe '#repository_raw_manifest' do
    let(:manifest) { '{schemaVersion: 2, layers:[]}' }

    it 'GET "/v2/:name/manifests/:reference' do
      stub_request(:get, 'http://registry/v2/group/test/manifests/my-tag')
        .with(headers: headers_with_accept_types_with_list)
        .to_return(status: 200, body: manifest, headers: {})

      expect(client.repository_raw_manifest('group/test', 'my-tag')).to eq(manifest)
    end

    it 'raises error' do
      stub_request(:get, 'http://registry/v2/group/test/manifests/my-tag')
        .with(headers: headers_with_accept_types_with_list)
        .to_return(status: 500, body: 'Something is wrong', headers: {})

      expect { client.repository_raw_manifest('group/test', 'my-tag') }
        .to raise_error(EE::ContainerRegistry::Client::Error, /500 - Something is wrong/)
    end
  end

  describe '#pull_blob' do
    before do
      stub_request(:get, "http://registry/v2/group/test/blobs/e2312abc")
          .with(headers: base_headers)
          .to_return(status: 302, headers: { 'Location' => 'http://download-link.com' })
    end

    it 'downloads file successfully when' do
      stub_request(:get, "http://download-link.com/")
        .to_return(status: 200, headers: { 'Content-Length' => '32456' })

      # With this stub we assert that there is no Authorization header in the request.
      # This also mimics the real case because Amazon s3 returns error too.
      stub_request(:get, "http://download-link.com/")
        .with(headers: base_headers)
        .to_return(status: 500)

      enumerator, size = client.pull_blob('group/test', 'e2312abc')

      expect(enumerator).to be_a_kind_of(HTTP::Response::Body)
      expect(size).to eq(32456)
    end

    it 'raises error when it can not download blob' do
      stub_request(:get, "http://download-link.com/")
        .to_return(status: 500, body: 'Something is wrong')

      expect { client.pull_blob('group/test', 'e2312abc') }
        .to raise_error(EE::ContainerRegistry::Client::Error, /500 - Something is wrong/)
    end

    it 'raises error when request is not authenticated' do
      stub_request(:get, "http://registry/v2/group/test/blobs/e2312abc")
          .with(headers: base_headers)
          .to_return(status: 401, body: 'Something is wrong')

      expect { client.pull_blob('group/test', 'e2312abc') }
        .to raise_error(EE::ContainerRegistry::Client::Error, /401 - Something is wrong/)
    end

    context 'when primary_api_url is specified with trailing slash' do
      let(:client) { described_class.new("http://registry/", options) }

      it 'builds correct URL' do
        stub_request(:get, "http://registry//v2/group/test/blobs/e2312abc")
          .with(headers: base_headers)
          .to_return(status: 500)

        stub_request(:get, "http://download-link.com/")
          .to_return(status: 200, headers: { 'Content-Length' => '32456' })

        enumerator, size = client.pull_blob('group/test', 'e2312abc')

        expect(enumerator).to be_a_kind_of(HTTP::Response::Body)
        expect(size).to eq(32456)
      end
    end

    context 'direct link to download, no redirect' do
      it 'downloads blob successfully' do
        stub_request(:get, "http://registry/v2/group/test/blobs/e2312abc")
            .with(headers: base_headers)
            .to_return(status: 200, headers: { 'Content-Length' => '32456' })

        enumerator, size = client.pull_blob('group/test', 'e2312abc')

        expect(enumerator).to be_a_kind_of(HTTP::Response::Body)
        expect(size).to eq(32456)
      end
    end
  end
end
