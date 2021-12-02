import mockGetProjectStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_storage.query.graphql.json';

export { mockGetProjectStorageStatisticsGraphQLResponse };

export const mockEmptyResponse = { data: { project: null } };

export const projects = [
  {
    id: '24',
    fullPath: 'h5bp/dummy-project',
    nameWithNamespace: 'H5bp / dummy project',
    avatarUrl: null,
    webUrl: 'http://localhost:3001/h5bp/dummy-project',
    name: 'dummy project',
    statistics: {
      commitCount: 1,
      storageSize: 41943,
      repositorySize: 41943,
      lfsObjectsSize: 0,
      buildArtifactsSize: 0,
      packagesSize: 0,
    },
    actualRepositorySizeLimit: 100000,
    totalCalculatedUsedStorage: 41943,
    totalCalculatedStorageLimit: 41943000,
  },
  {
    id: '8',
    fullPath: 'h5bp/html5-boilerplate',
    nameWithNamespace: 'H5bp / Html5 Boilerplate',
    avatarUrl: null,
    webUrl: 'http://localhost:3001/h5bp/html5-boilerplate',
    name: 'Html5 Boilerplate',
    statistics: {
      commitCount: 0,
      storageSize: 99000,
      repositorySize: 0,
      lfsObjectsSize: 0,
      buildArtifactsSize: 1272375,
      packagesSize: 0,
    },
    actualRepositorySizeLimit: 100000,
    totalCalculatedUsedStorage: 89000,
    totalCalculatedStorageLimit: 99430,
  },
  {
    id: '80',
    fullPath: 'twit/twitter',
    nameWithNamespace: 'Twitter',
    avatarUrl: null,
    webUrl: 'http://localhost:3001/twit/twitter',
    name: 'Twitter',
    statistics: {
      commitCount: 0,
      storageSize: 12933460,
      repositorySize: 209710,
      lfsObjectsSize: 209720,
      buildArtifactsSize: 1272375,
      packagesSize: 0,
    },
    actualRepositorySizeLimit: 100000,
    totalCalculatedUsedStorage: 13143170,
    totalCalculatedStorageLimit: 12143170,
  },
];

export const projectData = {
  storage: {
    totalUsage: '13.8 MiB',
    storageTypes: [
      {
        storageType: {
          id: 'buildArtifactsSize',
          name: 'Artifacts',
          description: 'Pipeline artifacts and job artifacts, created with CI/CD.',
          warningMessage:
            'Because of a known issue, the artifact total for some projects may be incorrect. For more details, read %{warningLinkStart}the epic%{warningLinkEnd}.',
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
  usageQuotasHelpPagePath: '/usage-quotas',
  buildArtifactsHelpPagePath: '/build-artifacts',
  lfsObjectsHelpPagePath: '/lsf-objects',
  packagesHelpPagePath: '/packages',
  repositoryHelpPagePath: '/repository',
  snippetsHelpPagePath: '/snippets',
  uploadsHelpPagePath: '/uploads',
  wikiHelpPagePath: '/wiki',
};

export const defaultProjectProvideValues = {
  projectPath: '/project-path',
  helpLinks: projectHelpLinks,
};
