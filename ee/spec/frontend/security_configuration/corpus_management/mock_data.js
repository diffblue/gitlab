const pageSize = 10;

const pipelines = {
  nodes: [
    {
      id: 'gid://gitlab/Packages::PackagePipelines/1',
      ref: 'farias-gl/go-fuzzing-example',
      path: 'gitlab-examples/security/security-reports/-/jobs/1107103952',
      createdAt: new Date(2020, 4, 3).toString(),
      updatedAt: new Date(2020, 4, 5).toString(),
    },
  ],
};

const packageFiles = {
  nodes: [
    {
      id: 'gid://gitlab/Packages::PackageFile/1',
      downloadPath: '/download-path',
      size: 4e8,
    },
  ],
};

export const corpuses = [
  {
    id: 'gid://gitlab/AppSec::Fuzzing::Coverage::Corpus/1',
    package: {
      id: 'gid://gitlab/Packages::Package/1',
      name: 'Corpus-sample-1-13830-23932',
      updatedAt: new Date(2021, 2, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    id: 'gid://gitlab/AppSec::Fuzzing::Coverage::Corpus/2',
    package: {
      id: 'gid://gitlab/Packages::Package/2',
      name: 'Corpus-sample-2-5830-2393',
      updatedAt: new Date(2021, 3, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    id: 'gid://gitlab/AppSec::Fuzzing::Coverage::Corpus/3',
    package: {
      id: 'gid://gitlab/Packages::Package/3',
      name: 'Corpus-sample-3-1431-4425',
      updatedAt: new Date(2021, 4, 12).toString(),
      pipelines: {
        nodes: [
          {
            ...pipelines.nodes[0],
            path: '',
          },
        ],
      },
      packageFiles: {
        nodes: [
          {
            id: 'gid://gitlab/Packages::PackageFile/1',
            downloadPath: '/download-path',
            size: 3.21e8,
          },
        ],
      },
    },
  },
  {
    id: 'gid://gitlab/AppSec::Fuzzing::Coverage::Corpus/4',
    package: {
      id: 'gid://gitlab/Packages::Package/3',
      name: 'Corpus-sample-4-5830-1393',
      updatedAt: new Date(2021, 5, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    id: 'gid://gitlab/AppSec::Fuzzing::Coverage::Corpus/5',
    package: {
      id: 'gid://gitlab/Packages::Package/4',
      name: 'Corpus-sample-5-13830-23932',
      updatedAt: new Date(2021, 6, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    id: 'gid://gitlab/AppSec::Fuzzing::Coverage::Corpus/6',
    package: {
      id: 'gid://gitlab/Packages::Package/5',
      name: 'Corpus-sample-6-2450-2393',
      updatedAt: new Date(2021, 7, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
];

export const generateCorpusesList = (quantity = pageSize) =>
  [...Array(quantity).keys()].map((index) => ({
    id: `gid://gitlab/AppSec::Fuzzing::Coverage::Corpus/${index + 1}`,
    package: {
      id: `gid://gitlab/Packages::Package/${index + 1}`,
      name: `Corpus-sample-${index + 1}-13830-23932`,
      updatedAt: new Date(2021, 2, 12).toString(),
      pipelines,
      packageFiles,
    },
  }));

export const getCorpusesQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/8',
      corpuses: {
        nodes: corpuses,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: 'start-cursor',
          endCursor: 'end-cursor',
        },
      },
    },
  },
};

export const getCorpusesBigListQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/8',
      corpuses: {
        nodes: generateCorpusesList(pageSize + 1),
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: 'start-cursor',
          endCursor: 'end-cursor',
        },
      },
    },
  },
};

export const deleteCorpusMutationResponse = {
  data: {
    destroyPackage: {
      errors: {},
    },
  },
};
