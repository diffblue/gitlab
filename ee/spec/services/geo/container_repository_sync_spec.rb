# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositorySync, :geo do
  let_it_be(:group) { create(:group, name: 'group') }
  let_it_be(:project) { create(:project, path: 'test', group: group) }
  let_it_be(:container_repository) { create(:container_repository, name: 'my_image', project: project) }

  let(:primary_api_url) { 'http://primary.registry.gitlab' }
  let(:secondary_api_url) { 'http://registry.gitlab' }
  let(:primary_repository_url) { "#{primary_api_url}/v2/#{container_repository.path}" }
  let(:secondary_repository_url ) { "#{secondary_api_url}/v2/#{container_repository.path}" }

  # Break symbol will be removed if JSON encode/decode operation happens so we use this
  # to prove that it does not happen and we preserve original human readable JSON
  let(:manifest) do
    "{" \
      "\n\"schemaVersion\":2," \
      "\n\"mediaType\":\"application/vnd.docker.distribution.manifest.v2+json\"," \
      "\n\"layers\":[" \
        "{\n\"mediaType\":\"application/vnd.docker.distribution.manifest.v2+json\",\n\"size\":3333,\n\"digest\":\"sha256:3333\"}," \
        "{\n\"mediaType\":\"application/vnd.docker.distribution.manifest.v2+json\",\n\"size\":4444,\n\"digest\":\"sha256:4444\"}," \
        "{\n\"mediaType\":\"application/vnd.docker.image.rootfs.foreign.diff.tar.gzip\",\n\"size\":5555,\n\"digest\":\"sha256:5555\",\n\"urls\":[\"https://foo.bar/v2/zoo/blobs/sha256:5555\"]}" \
      "]" \
    "}"
  end

  let(:manifest_list) do
    %Q(
      {
        "schemaVersion":2,
        "mediaType":"application/vnd.docker.distribution.manifest.list.v2+json",
        "manifests":[
          {
            "mediaType":"application/vnd.docker.distribution.manifest.v2+json",
            "size":6666,
            "digest":"sha256:6666",
            "platform":
              {
                "architecture":"arm64","os":"linux"
              }
          }
        ]
       }
       )
  end

  before do
    stub_container_registry_config(enabled: true, api_url: secondary_api_url)
    stub_registry_replication_config(enabled: true, primary_api_url: primary_api_url)
  end

  def stub_primary_repository_tags_requests(repository_url, tags)
    stub_request(:get, "#{repository_url}/tags/list")
      .to_return(
        status: 200,
        body: Gitlab::Json.dump(tags: tags.keys),
        headers: { 'Content-Type' => 'application/json' })

    tags.each do |tag, digest|
      stub_request(:head, "#{repository_url}/manifests/#{tag}")
        .to_return(status: 200, body: "", headers: { 'docker-content-digest' => digest })
    end
  end

  def stub_secondary_repository_tags_requests(repository_url, tags)
    stub_request(:get, "#{repository_url}/tags/list")
      .to_return(
        status: 200,
        body: Gitlab::Json.dump(tags: tags.keys),
        headers: { 'Content-Type' => 'application/json' })

    tags.each do |tag, digest|
      stub_request(:head, "#{repository_url}/manifests/#{tag}")
        .to_return(status: 200, body: "", headers: { 'docker-content-digest' => digest })
    end
  end

  def stub_primary_raw_manifest_request(repository_url, tag, manifest)
    stub_request(:get, "#{repository_url}/manifests/#{tag}")
      .to_return(status: 200, body: manifest, headers: {})
  end

  def stub_secondary_raw_manifest_request(repository_url, tag, manifest)
    stub_request(:get, "#{repository_url}/manifests/#{tag}")
      .to_return(status: 200, body: manifest, headers: {})
  end

  def stub_primary_raw_manifest_list_request(repository_url, tag, manifest)
    stub_request(:get, "#{repository_url}/manifests/#{tag}")
      .to_return(status: 200, body: manifest_list, headers: {})
  end

  def stub_secondary_push_manifest_request(repository_url, tag, manifest)
    stub_request(:put, "#{repository_url}/manifests/#{tag}")
      .with(body: manifest)
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_missing_blobs_requests(primary_repository_url, secondary_repository_url, blobs)
    blobs.each do |digest, missing|
      stub_request(:head, "#{secondary_repository_url}/blobs/#{digest}")
        .to_return(status: (missing ? 404 : 200), body: "", headers: {})

      next unless missing

      stub_request(:get, "#{primary_repository_url}/blobs/#{digest}")
        .to_return(status: 200, body: File.new(Rails.root.join('ee/spec/fixtures/ee_sample_schema.json')), headers: {})
    end
  end

  describe '#execute' do
    subject { described_class.new(container_repository) }

    context 'single manifest' do
      it 'determines list of tags to sync and to remove correctly' do
        stub_primary_repository_tags_requests(primary_repository_url, { 'tag-to-sync' => 'sha256:1111' })
        stub_secondary_repository_tags_requests(secondary_repository_url, { 'tag-to-remove' => 'sha256:2222' })
        stub_primary_raw_manifest_request(primary_repository_url, 'tag-to-sync', manifest)
        stub_missing_blobs_requests(primary_repository_url, secondary_repository_url, { 'sha256:3333' => true, 'sha256:4444' => false })
        stub_secondary_push_manifest_request(secondary_repository_url, 'tag-to-sync', manifest)

        expect(container_repository).to receive(:push_blob).with('sha256:3333', anything)
        expect(container_repository).not_to receive(:push_blob).with('sha256:4444', anything)
        expect(container_repository).not_to receive(:push_blob).with('sha256:5555', anything)
        expect(container_repository).to receive(:delete_tag_by_digest).with('sha256:2222')

        subject.execute
      end

      context 'when primary repository has no tags' do
        it 'removes secondary tags and does not fail' do
          stub_primary_repository_tags_requests(primary_repository_url, {})
          stub_secondary_repository_tags_requests(secondary_repository_url, { 'tag-to-remove' => 'sha256:2222' })

          expect(container_repository).to receive(:delete_tag_by_digest).with('sha256:2222')

          subject.execute
        end
      end
    end

    context 'manifest list' do
      it 'pushes the correct blobs and manifests' do
        stub_primary_repository_tags_requests(primary_repository_url, { 'tag-to-sync' => 'sha256:1111' })
        stub_secondary_repository_tags_requests(secondary_repository_url, {})
        stub_primary_raw_manifest_list_request(primary_repository_url, 'tag-to-sync', manifest_list)
        stub_primary_raw_manifest_request(primary_repository_url, 'sha256:6666', manifest)
        stub_secondary_raw_manifest_request(secondary_repository_url, 'sha256:6666', manifest)
        stub_missing_blobs_requests(primary_repository_url, secondary_repository_url, { 'sha256:3333' => true, 'sha256:4444' => false })

        expect(container_repository).to receive(:push_blob).with('sha256:3333', anything)
        expect(container_repository).to receive(:push_manifest).with('sha256:6666', anything, anything)
        expect(container_repository).to receive(:push_manifest).with('tag-to-sync', anything, anything)
        expect(container_repository).to receive(:delete_tag_by_digest).with('sha256:2222')

        subject.execute
      end
    end
  end
end
