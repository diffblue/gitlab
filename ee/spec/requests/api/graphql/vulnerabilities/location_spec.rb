# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.location', feature_category: :vulnerability_management do
  include GraphqlHelpers

  subject { graphql_data.dig('vulnerabilities', 'nodes') }

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }
  let_it_be(:agent) { create(:cluster_agent, project: project) }

  let_it_be(:fields) do
    <<~QUERY
      location {
        __typename
        ... on VulnerabilityLocationClusterImageScanning {
          image
          operatingSystem
          dependency {
            version
            package {
              name
            }
          }
          kubernetesResource {
            namespace
            kind
            name
            containerName
            clusterId
            agent {
              id
              name
            }
          }
        }
        ... on VulnerabilityLocationContainerScanning {
          image
          operatingSystem
          dependency {
            version
            package {
              name
            }
          }
        }
        ... on VulnerabilityLocationDependencyScanning {
          file
          dependency {
            version
            package {
              name
            }
          }
          blobPath
        }
        ... on VulnerabilityLocationDast {
          hostname
          param
          path
          requestMethod
        }
        ... on VulnerabilityLocationSast {
          endLine
          file
          startLine
          vulnerableClass
          vulnerableMethod
          blobPath
        }
        ... on VulnerabilityLocationSecretDetection {
          endLine
          file
          startLine
          vulnerableClass
          vulnerableMethod
          blobPath
        }
        ... on VulnerabilityLocationGeneric {
          description
        }
      }
    QUERY
  end

  let_it_be(:query) do
    graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, fields))
  end

  before do
    project.add_developer(user)
    stub_licensed_features(security_dashboard: true)

    post_graphql(query, current_user: user)
  end

  context 'when the vulnerability was found by a container scan' do
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project, report_type: :container_scanning)
    end

    let_it_be(:metadata) do
      {
        location: {
          image: 'vulnerable_image',
          operating_system: 'vulnerable_os',
          dependency: {
            version: '6.6.6',
            package: {
              name: 'vulnerable_container'
            }
          }
        }
      }
    end

    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        vulnerability: vulnerability,
        raw_metadata: metadata.to_json
      )
    end

    it 'returns a container location' do
      location = subject.first['location']

      expect(location['__typename']).to eq('VulnerabilityLocationContainerScanning')
      expect(location['image']).to eq('vulnerable_image')
      expect(location['operatingSystem']).to eq('vulnerable_os')
      expect(location['dependency']['version']).to eq('6.6.6')
      expect(location['dependency']['package']['name']).to eq('vulnerable_container')
    end
  end

  context 'when the vulnerability was found by a generic scanner' do
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project, report_type: :generic)
    end

    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        vulnerability: vulnerability,
        raw_metadata: metadata.to_json
      )
    end

    let_it_be(:metadata) do
      {
        description: "Something really bad"
      }
    end

    it 'returns a generic location' do
      location = subject.first['location']

      expect(location['__typename']).to eq('VulnerabilityLocationGeneric')
    end
  end

  context 'when the vulnerability was found by a cluster image scan' do
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project, report_type: :cluster_image_scanning)
    end

    let_it_be(:metadata) do
      {
        location: {
          image: 'vulnerable_image',
          operating_system: 'vulnerable_os',
          dependency: {
            version: '6.6.6',
            package: {
              name: 'vulnerable_container'
            }
          },
          kubernetes_resource: {
            namespace: "production",
            kind: "Deployment",
            name: "nginx-deployment",
            container_name: "nginx",
            cluster_id: "1",
            agent_id: agent.id.to_s
          }
        }
      }
    end

    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        vulnerability: vulnerability,
        raw_metadata: metadata.to_json
      )
    end

    it 'returns a cluster image scanning location' do
      location = subject.first['location']

      expect(location['__typename']).to eq('VulnerabilityLocationClusterImageScanning')
      expect(location['image']).to eq('vulnerable_image')
      expect(location['operatingSystem']).to eq('vulnerable_os')
      expect(location['dependency']['version']).to eq('6.6.6')
      expect(location['dependency']['package']['name']).to eq('vulnerable_container')
      expect(location['kubernetesResource']['namespace']).to eq('production')
      expect(location['kubernetesResource']['kind']).to eq('Deployment')
      expect(location['kubernetesResource']['name']).to eq('nginx-deployment')
      expect(location['kubernetesResource']['containerName']).to eq('nginx')
      expect(location['kubernetesResource']['clusterId']).to eq('gid://gitlab/Clusters::Cluster/1')
      expect(location['kubernetesResource']['agent']['id']).to eq("gid://gitlab/Clusters::Agent/#{agent.id}")
      expect(location['kubernetesResource']['agent']['name']).to eq(agent.name)
    end
  end

  context 'when the vulnerability was found by a dependency scan' do
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project, report_type: :dependency_scanning)
    end

    let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

    let_it_be(:metadata) do
      {
        location: {
          file: 'vulnerable_file',
          dependency: {
            version: '6.6.6',
            package: {
              name: 'vulnerable_package'
            }
          }
        }
      }
    end

    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        :with_pipeline,
        vulnerability: vulnerability,
        raw_metadata: metadata.to_json
      )
    end

    it 'returns a location in a dependency' do
      location = subject.first['location']

      expect(location['__typename']).to eq('VulnerabilityLocationDependencyScanning')
      expect(location['file']).to eq('vulnerable_file')
      expect(location['dependency']['version']).to eq('6.6.6')
      expect(location['dependency']['package']['name']).to eq('vulnerable_package')
    end
  end

  context 'when the vulnerability was found by a SAST scan' do
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project, report_type: :sast)
    end

    let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

    let_it_be(:metadata) do
      {
        location: {
          class: 'VulnerableClass',
          method: 'vulnerable_method',
          file: 'vulnerable_file',
          start_line: '420',
          end_line: '666',
          blob_path: 'blob/vulnerable_file'
        }
      }
    end

    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        :with_pipeline,
        vulnerability: vulnerability,
        raw_metadata: metadata.to_json
      )
    end

    it 'returns the file and line numbers where the vulnerability is located' do
      location = subject.first['location']

      expect(location['__typename']).to eq('VulnerabilityLocationSast')
      expect(location['file']).to eq('vulnerable_file')
      expect(location['startLine']).to eq('420')
      expect(location['endLine']).to eq('666')
      expect(location['vulnerableClass']).to eq('VulnerableClass')
      expect(location['vulnerableMethod']).to eq('vulnerable_method')
    end
  end

  context 'when the vulnerability was found by a secret detection scan' do
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project, report_type: :secret_detection)
    end

    let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

    let_it_be(:metadata) do
      {
        location: {
          class: 'VulnerableClass',
          method: 'vulnerable_method',
          file: 'vulnerable_file',
          start_line: '420',
          end_line: '666'
        }
      }
    end

    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        :with_pipeline,
        vulnerability: vulnerability,
        raw_metadata: metadata.to_json
      )
    end

    it 'returns the file and line numbers where the vulnerability is located' do
      location = subject.first['location']

      expect(location['__typename']).to eq('VulnerabilityLocationSecretDetection')
      expect(location['file']).to eq('vulnerable_file')
      expect(location['startLine']).to eq('420')
      expect(location['endLine']).to eq('666')
      expect(location['vulnerableClass']).to eq('VulnerableClass')
      expect(location['vulnerableMethod']).to eq('vulnerable_method')
    end
  end

  context 'when the vulnerability was found by a DAST scan' do
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project, report_type: :dast)
    end

    let_it_be(:metadata) do
      {
        location: {
          hostname: 'https://crimethinc.com',
          param: 'ARTICLE=may-day-2020',
          path: 'https://crimethinc.com/2020/04/22',
          request_method: 'GET'
        }
      }
    end

    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        vulnerability: vulnerability,
        raw_metadata: metadata.to_json
      )
    end

    it 'returns the URL where the vulnerability was found' do
      location = subject.first['location']

      expect(location['__typename']).to eq('VulnerabilityLocationDast')
      expect(location['hostname']).to eq('https://crimethinc.com')
      expect(location['param']).to eq('ARTICLE=may-day-2020')
      expect(location['path']).to eq('https://crimethinc.com/2020/04/22')
      expect(location['requestMethod']).to eq('GET')
    end
  end
end
