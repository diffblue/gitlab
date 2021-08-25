# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Client do
  let(:token) { '12345' }
  let(:options) { { token: token } }
  let(:client) { described_class.new("http://registry", options) }
  let(:push_blob_headers) do
    {
      'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
      'Authorization' => 'bearer 12345',
      'Content-Length' => '3',
      'Content-Type' => 'application/octet-stream',
      'User-Agent' => "GitLab/#{Gitlab::VERSION}"
    }
  end

  let(:headers_with_accept_types) do
    {
      'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
      'Authorization' => 'bearer 12345',
      'User-Agent' => "GitLab/#{Gitlab::VERSION}"
    }
  end

  let(:headers_with_accept_types_with_list) do
    {
      'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.list.v2+json',
      'Authorization' => 'bearer 12345',
      'User-Agent' => "GitLab/#{Gitlab::VERSION}"
    }
  end

  describe '#push_blob' do
    let(:file) do
      file = Tempfile.new('test1')
      file.write('bla')
      file.close
      file
    end

    it 'PUT /v2/:name/blobs/uploads/url?digest=mytag' do
      stub_request(:put, "http://registry/v2/group/test/blobs/uploads/abcd?digest=mytag")
        .with(headers: push_blob_headers)
        .to_return(status: 200, body: "", headers: {})

      stub_request(:post, "http://registry/v2/group/test/blobs/uploads/")
        .with(headers: headers_with_accept_types)
        .to_return(status: 200, body: "", headers: { 'Location' => 'http://registry/v2/group/test/blobs/uploads/abcd' })

      expect(client.push_blob('group/test', 'mytag', file.path)).to eq(true)
    end

    it 'raises error if response status is not 200' do
      stub_request(:put, "http://registry/v2/group/test/blobs/uploads/abcd?digest=mytag")
        .with(headers: push_blob_headers)
        .to_return(status: 404, body: "", headers: {})

      stub_request(:post, "http://registry/v2/group/test/blobs/uploads/")
        .with(headers: headers_with_accept_types)
        .to_return(status: 200, body: "", headers: { 'Location' => 'http://registry/v2/group/test/blobs/uploads/abcd' })

      expect { client.push_blob('group/test', 'mytag', file.path) }
        .to raise_error(EE::ContainerRegistry::Client::Error)
    end
  end

  describe '#push_manifest' do
    let(:manifest) { 'manifest' }
    let(:manifest_type) { 'application/vnd.docker.distribution.manifest.v2+json' }
    let(:manifest_headers) do
      {
          'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
          'Authorization' => 'bearer 12345',
          'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json',
          'User-Agent' => "GitLab/#{Gitlab::VERSION}"
      }
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
  end

  describe '#pull_blob' do
    let(:pull_blob_headers) do
      {
        'Authorization' => 'Bearer 12345',
        'User-Agent' => "GitLab/#{Gitlab::VERSION}"
      }
    end

    before do
      stub_request(:get, "http://registry/v2/group/test/blobs/e2312abc")
          .with(headers: pull_blob_headers)
          .to_return(status: 302, headers: { "Location" => 'http://download-link.com' })
    end

    it 'downloads file successfully when' do
      stub_request(:get, "http://download-link.com/")
        .to_return(status: 200)

      # With this stub we assert that there is no Authorization header in the request.
      # This also mimics the real case because Amazon s3 returns error too.
      stub_request(:get, "http://download-link.com/")
        .with(headers: pull_blob_headers)
        .to_return(status: 500)

      expect(client.pull_blob('group/test', 'e2312abc')).to be_a_kind_of(Tempfile)
    end

    it 'raises error when it can not download blob' do
      stub_request(:get, "http://download-link.com/")
        .to_return(status: 500)

      expect { client.pull_blob('group/test', 'e2312abc') }.to raise_error(EE::ContainerRegistry::Client::Error)
    end

    it 'raises error when request is not authenticated' do
      stub_request(:get, "http://registry/v2/group/test/blobs/e2312abc")
          .with(headers: pull_blob_headers)
          .to_return(status: 401)

      expect { client.pull_blob('group/test', 'e2312abc') }.to raise_error(EE::ContainerRegistry::Client::Error)
    end

    context 'when primary_api_url is specified with trailing slash' do
      let(:client) { described_class.new("http://registry/", options) }

      it 'builds correct URL' do
        stub_request(:get, "http://registry//v2/group/test/blobs/e2312abc")
          .with(headers: pull_blob_headers)
          .to_return(status: 500)

        stub_request(:get, "http://download-link.com/")
          .to_return(status: 200)

        expect(client.pull_blob('group/test', 'e2312abc')).to be_a_kind_of(Tempfile)
      end
    end

    context 'direct link to download, no redirect' do
      it 'downloads blob successfully' do
        stub_request(:get, "http://registry/v2/group/test/blobs/e2312abc")
            .with(headers: pull_blob_headers)
            .to_return(status: 200)

        expect(client.pull_blob('group/test', 'e2312abc')).to be_a_kind_of(Tempfile)
      end
    end
  end
end
