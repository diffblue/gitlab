export const environment = {
  name: 'production',
  size: 1,
  state: 'stopped',
  external_url: 'http://external.com',
  environment_type: null,
  last_deployment: {
    id: 66,
    iid: 6,
    sha: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
    ref: {
      name: 'main',
      ref_url: 'root/ci-folders/tree/main',
    },
    tag: true,
    'last?': true,
    user: {
      name: 'Administrator',
      username: 'root',
      id: 1,
      state: 'active',
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      web_url: 'http://localhost:3000/root',
    },
    commit: {
      id: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
      short_id: '500aabcb',
      title: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      created_at: '2016-11-07T18:28:13.000+00:00',
      message: 'Update .gitlab-ci.yml',
      author: {
        name: 'Administrator',
        username: 'root',
        id: 1,
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
        web_url: 'http://localhost:3000/root',
      },
      commit_path: '/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
    },
    deployable: {
      id: 1279,
      name: 'deploy',
      build_path: '/root/ci-folders/builds/1279',
      retry_path: '/root/ci-folders/builds/1279/retry',
      created_at: '2016-11-29T18:11:58.430Z',
      updated_at: '2016-11-29T18:11:58.430Z',
    },
    manual_actions: [
      {
        name: 'action',
        play_path: '/play',
      },
    ],
    deployed_at: '2016-11-29T18:11:58.430Z',
  },
  upcoming_deployment: {
    id: 66,
    iid: 6,
    sha: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
    ref: {
      name: 'main',
      ref_url: 'root/ci-folders/tree/main',
    },
    tag: true,
    'last?': true,
    user: {
      name: 'Administrator',
      username: 'root',
      id: 1,
      state: 'active',
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      web_url: 'http://localhost:3000/root',
    },
    commit: {
      id: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
      short_id: '500aabcb',
      title: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      created_at: '2016-11-07T18:28:13.000+00:00',
      message: 'Update .gitlab-ci.yml',
      author: {
        name: 'Administrator',
        username: 'root',
        id: 1,
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
        web_url: 'http://localhost:3000/root',
      },
      commit_path: '/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
    },
    deployable: {
      id: 1279,
      name: 'deploy',
      build_path: '/root/ci-folders/builds/1279',
      retry_path: '/root/ci-folders/builds/1279/retry',
      created_at: '2016-11-29T18:11:58.430Z',
      updated_at: '2016-11-29T18:11:58.430Z',
      status: {
        text: 'success',
        icon: 'status_success',
      },
    },
    manual_actions: [
      {
        name: 'action',
        play_path: '/play',
      },
    ],
    approvals: [
      {
        user: {
          id: 11,
          username: 'marianna',
          name: 'Cristy Quitzon',
          state: 'active',
          avatarUrl: 'avatar/930d17951d0d1dd25944319f05a75707',
          webUrl: '/marianna',
        },
        status: 'approved',
        createdAt: Date.now(),
        comment: 'this is a test comment',
      },
    ],
    can_approve_deployment: true,
    deployed_at: '2016-11-29T18:11:58.430Z',
    pending_approval_count: 5,
  },
  required_approval_count: 10,
  tier: 'production',
  has_stop_action: true,
  environment_path: 'root/ci-folders/environments/31',
  log_path: 'root/ci-folders/environments/31/logs',
  created_at: '2016-11-07T11:11:16.525Z',
  updated_at: '2016-11-10T15:55:58.778Z',
};

const sharedEnvironmentData = (id) => ({
  environment_path: `/root/review-app/environments/${id}`,
  external_url: null,
  folderName: 'build',
  has_stop_action: false,
  id,
  last_deployment: null,
  rollout_status: {},
  state: 'available',
  stop_path: `/root/review-app/environments/${id}/stop`,
});

export const environmentsList = [
  {
    name: 'DEV',
    size: 1,
    environment_type: null,
    created_at: '2017-01-31T10:53:46.894Z',
    updated_at: '2017-01-31T10:53:46.894Z',
    ...sharedEnvironmentData(7),
  },
  {
    name: 'build/update-README',
    size: 5,
    environment_type: 'build',
    created_at: '2017-02-01T19:42:18.400Z',
    updated_at: '2017-02-01T19:42:18.400Z',
    ...sharedEnvironmentData(12),
  },
];

export const serverDataList = [
  {
    name: 'DEV',
    size: 1,
    latest: {
      name: 'DEV',
      environment_type: null,
      created_at: '2017-01-31T10:53:46.894Z',
      updated_at: '2017-01-31T10:53:46.894Z',
      ...sharedEnvironmentData(7),
    },
  },
  {
    name: 'build',
    size: 5,
    latest: {
      name: 'build/update-README',
      environment_type: 'build',
      created_at: '2017-02-01T19:42:18.400Z',
      updated_at: '2017-02-01T19:42:18.400Z',
      ...sharedEnvironmentData(12),
    },
  },
  {
    name: 'build',
    size: 1,
    latest: {
      name: 'build/update-README',
      environment_type: 'build',
      created_at: '2017-02-01T19:42:18.400Z',
      updated_at: '2017-02-01T19:42:18.400Z',
      ...sharedEnvironmentData(15),
    },
  },
];
