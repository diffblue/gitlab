import mockGetProjectStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_storage.query.graphql.json';
import mockGetNamespaceStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/namespace_storage.query.graphql.json';

export {
  mockGetProjectStorageStatisticsGraphQLResponse,
  mockGetNamespaceStorageStatisticsGraphQLResponse,
};

export const projects =
  mockGetNamespaceStorageStatisticsGraphQLResponse.data.namespace.projects.nodes;
export const mockEmptyResponse = { data: { project: null } };

export const projectData = {
  storage: {
    totalUsage: '13.8 MiB',
    storageTypes: [
      {
        storageType: {
          id: 'containerRegistrySize',
          name: 'Container Registry',
          description: 'Gitlab-integrated Docker Container Registry for storing Docker Images.',
          helpPath: '/container_registry',
        },
        value: 3_900_000,
      },
      {
        storageType: {
          id: 'buildArtifactsSize',
          name: 'Artifacts',
          description: 'Pipeline artifacts and job artifacts, created with CI/CD.',
          helpPath: '/build-artifacts',
        },
        value: 400000,
      },
      {
        storageType: {
          id: 'lfsObjectsSize',
          name: 'LFS storage',
          description: 'Audio samples, videos, datasets, and graphics.',
          helpPath: '/lsf-objects',
        },
        value: 4800000,
      },
      {
        storageType: {
          id: 'packagesSize',
          name: 'Packages',
          description: 'Code packages and container images.',
          helpPath: '/packages',
        },
        value: 3800000,
      },
      {
        storageType: {
          id: 'repositorySize',
          name: 'Repository',
          description: 'Git repository.',
          helpPath: '/repository',
        },
        value: 3900000,
      },
      {
        storageType: {
          id: 'snippetsSize',
          name: 'Snippets',
          description: 'Shared bits of code and text.',
          helpPath: '/snippets',
        },
        value: 0,
      },
      {
        storageType: {
          id: 'uploadsSize',
          name: 'Uploads',
          description: 'File attachments and smaller design graphics.',
          helpPath: '/uploads',
        },
        value: 900000,
      },
      {
        storageType: {
          id: 'wikiSize',
          name: 'Wiki',
          description: 'Wiki content.',
          helpPath: '/wiki',
        },
        value: 300000,
      },
    ],
  },
};

export const projectHelpLinks = {
  containerRegistry: '/container_registry',
  usageQuotas: '/usage-quotas',
  buildArtifacts: '/build-artifacts',
  lfsObjects: '/lsf-objects',
  packages: '/packages',
  repository: '/repository',
  snippets: '/snippets',
  uploads: '/uploads',
  wiki: '/wiki',
};

export const defaultProjectProvideValues = {
  projectPath: '/project-path',
  helpLinks: projectHelpLinks,
};

export const defaultNamespaceProvideValues = {
  namespaceId: '42',
  namespacePath: 'h5bp',
  defaultPerPage: 20,
  purchaseStorageUrl: '',
  buyAddonTargetAttr: '_blank',
  helpLinks: projectHelpLinks,
};

export const namespaceData = {
  totalUsage: 'Not applicable.',
  limit: 10000000,
  projects: { data: projects },
};

export const withRootStorageStatistics = {
  projects,
  limit: 10000000,
  totalUsage: 129334601,
  containsLockedProjects: true,
  repositorySizeExcessProjectCount: 1,
  totalRepositorySizeExcess: 2321,
  totalRepositorySize: 1002321,
  additionalPurchasedStorageSize: 321,
  actualRepositorySizeLimit: 1002321,
  rootStorageStatistics: {
    containerRegistrySize: 3_900_000,
    storageSize: 129334601,
    repositorySize: 46012030,
    lfsObjectsSize: 4329334601203,
    buildArtifactsSize: 1272375,
    packagesSize: 123123120,
    wikiSize: 1000,
    snippetsSize: 10000,
  },
};

export const statisticsCardDefaultProps = {
  totalStorage: 100 * 1024,
  usedStorage: 50 * 1024,
  hideProgressBar: false,
  loading: false,
};

export const mockedNamespaceStorageResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/84',
      name: 'wandercatgroup2',
      storageSizeLimit: 0,
      actualRepositorySizeLimit: 10737418240,
      additionalPurchasedStorageSize: 0,
      totalRepositorySizeExcess: 0,
      totalRepositorySize: 20971,
      containsLockedProjects: false,
      repositorySizeExcessProjectCount: 0,
      rootStorageStatistics: {
        containerRegistrySize: 3_900_000,
        storageSize: 125771,
        repositorySize: 20971,
        lfsObjectsSize: 0,
        buildArtifactsSize: 0,
        pipelineArtifactsSize: 0,
        packagesSize: 0,
        wikiSize: 104800,
        snippetsSize: 0,
        uploadsSize: 0,
        __typename: 'RootStorageStatistics',
      },
      projects: {
        nodes: [
          {
            id: 'gid://gitlab/Project/20',
            fullPath: 'wandercatgroup2/not-so-empty-project',
            nameWithNamespace: 'wandercatgroup2 / not so empty project',
            avatarUrl: null,
            webUrl: 'http://gdk.test:3000/wandercatgroup2/not-so-empty-project',
            name: 'not so empty project',
            repositorySizeExcess: 0,
            actualRepositorySizeLimit: 10737418240,
            statistics: {
              commitCount: 1,
              storageSize: 125771,
              repositorySize: 20971,
              lfsObjectsSize: 0,
              containerRegistrySize: 0,
              buildArtifactsSize: 0,
              packagesSize: 0,
              wikiSize: 104800,
              snippetsSize: 0,
              uploadsSize: 0,
              __typename: 'ProjectStatistics',
            },
            __typename: 'Project',
          },
          {
            id: 'gid://gitlab/Project/21',
            fullPath: 'wandercatgroup2/not-so-empty-project1',
            nameWithNamespace: 'wandercatgroup2 / not so empty project',
            avatarUrl: null,
            webUrl: 'http://gdk.test:3000/wandercatgroup2/not-so-empty-project',
            name: 'not so empty project',
            repositorySizeExcess: 0,
            actualRepositorySizeLimit: 10737418240,
            statistics: {
              commitCount: 1,
              storageSize: 125771,
              repositorySize: 20971,
              lfsObjectsSize: 0,
              containerRegistrySize: 0,
              buildArtifactsSize: 0,
              packagesSize: 0,
              wikiSize: 104800,
              snippetsSize: 0,
              uploadsSize: 0,
              __typename: 'ProjectStatistics',
            },
            __typename: 'Project',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjIwIiwiZXhjZXNzX3N0b3JhZ2UiOiItMTA3MzczOTcyNjkifQ',
          endCursor: 'eyJpZCI6IjIwIiwiZXhjZXNzX3N0b3JhZ2UiOiItMTA3MzczOTcyNjkifQ',
        },
        __typename: 'ProjectConnection',
      },
      __typename: 'Namespace',
    },
  },
};

export const mockDependencyProxyResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/84',
      dependencyProxyTotalSize: '0 Bytes',
      __typename: 'Group',
    },
  },
};
