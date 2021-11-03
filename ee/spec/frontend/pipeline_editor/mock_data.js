export const mockProjectNamespace = 'user1';
export const mockProjectPath = 'project1';
export const mockCommitSha = 'aabbccdd';
export const mockProjectFullPath = `${mockProjectNamespace}/${mockProjectPath}`;

export const mockLinkedPipelines = ({ hasDownstream = true, hasUpstream = true } = {}) => {
  let upstream = null;
  let downstream = {
    nodes: [],
    __typename: 'PipelineConnection',
  };

  if (hasDownstream) {
    downstream = {
      nodes: [
        {
          id: 'gid://gitlab/Ci::Pipeline/612',
          path: '/root/job-log-sections/-/pipelines/612',
          project: { name: 'job-log-sections', __typename: 'Project' },
          detailedStatus: {
            group: 'success',
            icon: 'status_success',
            label: 'passed',
            __typename: 'DetailedStatus',
          },
          __typename: 'Pipeline',
        },
      ],
      __typename: 'PipelineConnection',
    };
  }

  if (hasUpstream) {
    upstream = {
      id: 'gid://gitlab/Ci::Pipeline/610',
      path: '/root/trigger-downstream/-/pipelines/610',
      project: { name: 'trigger-downstream', __typename: 'Project' },
      detailedStatus: {
        group: 'success',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      __typename: 'Pipeline',
    };
  }

  return {
    data: {
      project: {
        pipeline: {
          path: '/root/ci-project/-/pipelines/790',
          downstream,
          upstream,
        },
        __typename: 'Project',
      },
    },
  };
};

export const mockProjectPipeline = ({ hasStages = true } = {}) => {
  const stages = hasStages
    ? {
        edges: [
          {
            node: {
              id: 'gid://gitlab/Ci::Stage/605',
              name: 'prepare',
              status: 'success',
              detailedStatus: {
                detailsPath: '/root/sample-ci-project/-/pipelines/268#prepare',
                group: 'success',
                hasDetails: true,
                icon: 'status_success',
                id: 'success-605-605',
                label: 'passed',
                text: 'passed',
                tooltip: 'passed',
              },
            },
          },
        ],
      }
    : null;

  return {
    pipeline: {
      commitPath: '/-/commit/aabbccdd',
      id: 'gid://gitlab/Ci::Pipeline/118',
      iid: '28',
      shortSha: mockCommitSha,
      status: 'SUCCESS',
      detailedStatus: {
        detailsPath: '/root/sample-ci-project/-/pipelines/118',
        group: 'success',
        icon: 'status_success',
        text: 'passed',
      },
      stages,
    },
  };
};
