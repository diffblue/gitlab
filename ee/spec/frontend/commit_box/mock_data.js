export const mockDownstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        path: '/root/ci-project/-/pipelines/790',
        id: 'pipeline-1',
        downstream: {
          nodes: [
            {
              id: 'gid://gitlab/Ci::Pipeline/612',
              path: '/root/job-log-sections/-/pipelines/612',
              project: { id: '1', name: 'job-log-sections', __typename: 'Project' },
              detailedStatus: {
                id: 'status-1',
                group: 'success',
                icon: 'status_success',
                label: 'passed',
                __typename: 'DetailedStatus',
              },
              __typename: 'Pipeline',
            },
          ],
          __typename: 'PipelineConnection',
        },
        upstream: null,
      },
      __typename: 'Project',
    },
  },
};

export const mockUpstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        id: 'pipeline-1',
        path: '/root/ci-project/-/pipelines/790',
        downstream: {
          nodes: [],
          __typename: 'PipelineConnection',
        },
        upstream: {
          id: 'gid://gitlab/Ci::Pipeline/610',
          path: '/root/trigger-downstream/-/pipelines/610',
          project: { id: '1', name: 'trigger-downstream', __typename: 'Project' },
          detailedStatus: {
            id: 'status-1',
            group: 'success',
            icon: 'status_success',
            label: 'passed',
            __typename: 'DetailedStatus',
          },
          __typename: 'Pipeline',
        },
      },
      __typename: 'Project',
    },
  },
};

export const mockUpstreamDownstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        id: 'pipeline-1',
        path: '/root/ci-project/-/pipelines/790',
        downstream: {
          nodes: [
            {
              id: 'gid://gitlab/Ci::Pipeline/612',
              path: '/root/job-log-sections/-/pipelines/612',
              project: { id: '1', name: 'job-log-sections', __typename: 'Project' },
              detailedStatus: {
                id: 'status-1',
                group: 'success',
                icon: 'status_success',
                label: 'passed',
                __typename: 'DetailedStatus',
              },
              __typename: 'Pipeline',
            },
          ],
          __typename: 'PipelineConnection',
        },
        upstream: {
          id: 'gid://gitlab/Ci::Pipeline/610',
          path: '/root/trigger-downstream/-/pipelines/610',
          project: { id: '1', name: 'trigger-downstream', __typename: 'Project' },
          detailedStatus: {
            id: 'status-1',
            group: 'success',
            icon: 'status_success',
            label: 'passed',
            __typename: 'DetailedStatus',
          },
          __typename: 'Pipeline',
        },
      },
      __typename: 'Project',
    },
  },
};

export const mockStages = [
  {
    id: 'stage-1',
    name: 'build',
    title: 'build: passed',
    status: {
      id: 'status-1',
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/611#build',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/611#build',
    dropdown_path: '/root/ci-project/-/pipelines/611/stage.json?stage=build',
  },
  {
    id: 'stage-2',
    name: 'test',
    title: 'test: passed',
    status: {
      id: 'status-2',
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/611#test',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/611#test',
    dropdown_path: '/root/ci-project/-/pipelines/611/stage.json?stage=test',
  },
  {
    id: 'stage-3',
    name: 'test_two',
    title: 'test_two: passed',
    status: {
      id: 'status-3',
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/611#test_two',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/611#test_two',
    dropdown_path: '/root/ci-project/-/pipelines/611/stage.json?stage=test_two',
  },
  {
    id: 'stage-4',
    name: 'manual',
    title: 'manual: skipped',
    status: {
      id: 'status-4',
      icon: 'status_skipped',
      text: 'skipped',
      label: 'skipped',
      group: 'skipped',
      tooltip: 'skipped',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/611#manual',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
      action: {
        id: 'action-4',
        icon: 'play',
        title: 'Play all manual',
        path: '/root/ci-project/-/pipelines/611/stages/manual/play_manual',
        method: 'post',
        button_title: 'Play all manual',
      },
    },
    path: '/root/ci-project/-/pipelines/611#manual',
    dropdown_path: '/root/ci-project/-/pipelines/611/stage.json?stage=manual',
  },
  {
    id: 'stage-5',
    name: 'deploy',
    title: 'deploy: passed',
    status: {
      id: 'status-5',
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/611#deploy',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/611#deploy',
    dropdown_path: '/root/ci-project/-/pipelines/611/stage.json?stage=deploy',
  },
  {
    id: 'stage-6',
    name: 'qa',
    title: 'qa: passed',
    status: {
      id: 'status-6',
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/611#qa',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/611#qa',
    dropdown_path: '/root/ci-project/-/pipelines/611/stage.json?stage=qa',
  },
];
