const pipelines = {
  nodes: [
    {
      ref: 'farias-gl/go-fuzzing-example',
      path: 'gitlab-examples/security/security-reports/-/jobs/1107103952',
      updatedAt: new Date(2020, 4, 3).toString(),
    },
  ],
};

const packageFiles = {
  nodes: [
    {
      downloadPath: '/download-path',
      size: 4e8,
    },
  ],
};

export const corpuses = [
  {
    package: {
      name: 'Corpus-sample-1-13830-23932',
      updatedAt: new Date(2021, 2, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    package: {
      name: 'Corpus-sample-2-5830-2393',
      updatedAt: new Date(2021, 3, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    package: {
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
            downloadPath: '/download-path',
            size: 3.21e8,
          },
        ],
      },
    },
  },
  {
    package: {
      name: 'Corpus-sample-4-5830-1393',
      updatedAt: new Date(2021, 5, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    package: {
      name: 'Corpus-sample-5-13830-23932',
      updatedAt: new Date(2021, 6, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
  {
    package: {
      name: 'Corpus-sample-6-2450-2393',
      updatedAt: new Date(2021, 7, 12).toString(),
      pipelines,
      packageFiles,
    },
  },
];
