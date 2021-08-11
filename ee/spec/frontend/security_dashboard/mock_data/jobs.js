export const mockPipelineJobs = [
  {
    name: 'my_fuzz_target',
    artifacts: {
      nodes: [
        {
          downloadPath: '/debug-cov-fuzz-project/-/jobs/1133/artifacts/download?file_type=trace',
          fileType: 'TRACE',
          __typename: 'CiJobArtifact',
        },
        {
          downloadPath:
            'debug-cov-fuzz-project/-/jobs/1133/artifacts/download?file_type=coverage_fuzzing',
          fileType: 'COVERAGE_FUZZING',
          __typename: 'CiJobArtifact',
        },
        {
          downloadPath: '/debug-cov-fuzz-project/-/jobs/1133/artifacts/download?file_type=metadata',
          fileType: 'METADATA',
          __typename: 'CiJobArtifact',
        },
        {
          downloadPath: '/debug-cov-fuzz-project/-/jobs/1133/artifacts/download?file_type=archive',
          fileType: 'ARCHIVE',
          __typename: 'CiJobArtifact',
        },
      ],
      __typename: 'CiJobArtifactConnection',
    },
    __typename: 'CiJob',
  },
  {
    name: 'gosec-sast',
    artifacts: {
      nodes: [
        {
          downloadPath: '/debug-cov-fuzz-project/-/jobs/1131/artifacts/download?file_type=trace',
          fileType: 'TRACE',
          __typename: 'CiJobArtifact',
        },
        {
          downloadPath: '/debug-cov-fuzz-project/-/jobs/1131/artifacts/download?file_type=sast',
          fileType: 'SAST',
          __typename: 'CiJobArtifact',
        },
      ],
      __typename: 'CiJobArtifactConnection',
    },
    __typename: 'CiJob',
  },
];
