export const catalogSharedDataMock = {
  data: {
    ciCatalogResource: {
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/1`,
      icon: null,
      description: 'This is the description of the repo',
      name: 'Ruby',
      rootNamespace: { id: 1, fullPath: '/group/project', name: 'my-dumb-project' },
      starCount: 1,
      forksCount: 2,
      latestVersion: {
        __typename: 'Release',
        id: '3',
        tagName: '1.0.0',
        tagPath: 'path/to/release',
        releasedAt: Date.now(),
        author: { id: 1, webUrl: 'profile/1', name: 'username' },
      },
      webPath: 'path/to/project',
    },
  },
};

export const catalogAdditionalDetailsMock = {
  data: {
    ciCatalogResource: {
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/1`,
      openIssuesCount: 4,
      openMergeRequestsCount: 10,
      readmeHtml: '<h1>Hello world</h1>',
      versions: {
        __typename: 'ReleaseConnection',
        nodes: [
          {
            __typename: 'Release',
            id: 'gid://gitlab/Release/3',
            commit: {
              __typename: 'Commit',
              id: 'gid://gitlab/CommitPresenter/afa936495f20e08c26ed4a67130ee2166f94fa6e',
              pipelines: {
                __typename: 'PipelineConnection',
                nodes: [
                  {
                    __typename: 'Pipeline',
                    id: 'gid://gitlab/Ci::Pipeline/583',
                    detailedStatus: {
                      __typename: 'DetailedStatus',
                      id: 'success-583-583',
                      detailsPath: '/root/cicd-circular/-/pipelines/583',
                      icon: 'status_success',
                      text: 'passed',
                      group: 'success',
                    },
                  },
                ],
              },
            },
            tagName: 'v1.0.2',
            releasedAt: '2022-08-23T17:19:09Z',
          },
        ],
      },
    },
  },
};

const generateResourcesNodes = (count = 20, startId = 0) => {
  const nodes = [];
  for (let i = startId; i < startId + count; i += 1) {
    nodes.push({
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/${i}`,
      description: `This is a component that does a bunch of stuff and is really just a number: ${i}`,
      forksCount: 5,
      icon: 'my-icon',
      name: `My component #${i}`,
      rootNamespace: {
        id: 1,
        __typename: 'Namespace',
        name: 'namespaceName',
        path: 'namespacePath',
      },
      starCount: 10,
      latestVersion: {
        __typename: 'Release',
        id: '3',
        tagName: '1.0.0',
        tagPath: 'path/to/release',
        releasedAt: Date.now(),
        author: { id: 1, webUrl: 'profile/1', name: 'username' },
      },
      webPath: 'path/to/project',
    });
  }

  return nodes;
};

export const mockCatalogResourceItem = generateResourcesNodes(1)[0];
