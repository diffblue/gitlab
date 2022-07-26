# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Locations::ContainerScanning do
  let(:params) do
    {
      image: 'registry.gitlab.com/my/project:latest',
      operating_system: 'debian:9',
      package_name: 'glibc',
      package_version: '1.2.3'
    }
  end

  let(:mandatory_params) { %i[image operating_system] }
  let(:expected_fingerprint) { Digest::SHA1.hexdigest('registry.gitlab.com/my/project:glibc') }
  let(:expected_fingerprint_path) { 'registry.gitlab.com/my/project:glibc' }

  it_behaves_like 'vulnerability location'

  subject { described_class.new(**params) }

  describe 'fingerprint' do
    sha1_of = -> (input) { Digest::SHA1.hexdigest(input) }

    where(:image, :default_branch_image, :valid_default_branch_image, :expected_fingerprint_input) do
      [
        ['alpine:3.7.3', nil, false, 'alpine:3.7.3:glibc'],
        ['alpine:3.7', nil, false, 'alpine:3.7:glibc'],
        ['alpine:8101518288111119448185914762536722131810', nil, false, 'alpine:glibc'],
        ['alpine:1.0.0-beta', nil, false, 'alpine:1.0.0-beta:glibc'],
        [
          'gdk.local:5000/group/project/branch:307e0a35643f63652a713d0820db7c388012f724',
          nil,
          false,
          'gdk.local:5000/group/project/branch:glibc'
        ],
        [
          'registry.gitlab.com/group/project/tmp:af864bd61230d3d694eb01d6205b268b4ad63ac0',
          nil,
          false,
          'registry.gitlab.com/group/project/tmp:glibc'
        ],
        [
          'registry.gitlab.com/group/project/feature:5b1a4a921d7a50c3757aae3f7df2221878775af4',
          'registry.gitlab.com/group/project/master:ec301f43f14a2b477806875e49cfc4d3fa0d22c3',
          true,
          'registry.gitlab.com/group/project/master:glibc'
        ],
        [
          'registry.gitlab.com/group/project/feature:d6704dc0b8e33fb550a86f7847d6a3036d4f8bd5',
          'registry.gitlab.com/group/project:latest',
          true,
          'registry.gitlab.com/group/project:glibc'
        ],
        [
          'registry.gitlab.com/group/project@sha256:a418bbb80b9411f9a08025baa4681e192aaafd16505039bdcb113ccdb90a88fd',
          'registry.gitlab.com/group/project:latest',
          true,
          'registry.gitlab.com/group/project:glibc'
        ],
        [
          'registry.gitlab.com/group/project/feature:latest',
          'registry.gitlab.com/group/project:1.0.0',
          true,
          'registry.gitlab.com/group/project:1.0.0:glibc'
        ],
        [
          'registry.gitlab.com/group/project/feature:latest',
          'registry.gitlab.com/group/project:1.0.0',
          false,
          'registry.gitlab.com/group/project/feature:glibc'
        ]
      ]
    end

    with_them do
      let(:params) do
        {
          image: image,
          default_branch_image: default_branch_image,
          operating_system: 'debian:9',
          package_name: 'glibc',
          package_version: '1.2.3',
          default_branch_image_validator: instance_double(
            Gitlab::Ci::Parsers::Security::Validators::DefaultBranchImageValidator,
            valid?: valid_default_branch_image
          )
        }
      end

      specify { expect(subject.fingerprint).to eq(sha1_of.call(expected_fingerprint_input)) }
    end
  end
end
