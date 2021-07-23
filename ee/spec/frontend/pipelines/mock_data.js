export const triggered = [
  {
    id: 602,
    user: {
      id: 1,
      name: 'Administrator',
      username: 'root',
      state: 'active',
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      web_url: 'http://gdk.test:3000/root',
      show_status: false,
      path: '/root',
    },
    active: false,
    coverage: null,
    source: 'pipeline',
    source_job: { name: 'trigger_job_on_mr' },
    path: '/root/job-log-sections/-/pipelines/602',
    details: {
      status: {
        icon: 'status_success',
        text: 'passed',
        label: 'passed',
        group: 'success',
        tooltip: 'passed',
        has_details: true,
        details_path: '/root/job-log-sections/-/pipelines/602',
        illustration: null,
        favicon:
          '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
      },
    },
    project: {
      id: 36,
      name: 'job-log-sections',
      full_path: '/root/job-log-sections',
      full_name: 'Administrator / job-log-sections',
    },
  },
];

export const triggeredBy = {
  id: 614,
  user: {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    web_url: 'http://gdk.test:3000/root',
    show_status: false,
    path: '/root',
  },
  active: false,
  coverage: null,
  source: 'web',
  source_job: { name: null },
  path: '/root/trigger-downstream/-/pipelines/614',
  details: {
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/trigger-downstream/-/pipelines/614',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
  },
  project: {
    id: 42,
    name: 'trigger-downstream',
    full_path: '/root/trigger-downstream',
    full_name: 'Administrator / trigger-downstream',
  },
};
