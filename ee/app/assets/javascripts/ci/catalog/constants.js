/* eslint-disable @gitlab/require-i18n-strings */
export const mockCatalogResourceList = [
  {
    id: 1,
    namespace: 'GitLab.org',
    group: 'GitLab',
    name: 'docker-template',
    latestVersion: '1.0.0',
    description: 'Quickly and easily install/configure/use in any GitLab job',
    icon: 'docker',
    lastUpdate: {
      time: new Date(),
      user: {
        id: '1',
        name: 'user',
        webUrl: 'path/to/user',
      },
    },
    statistics: {
      forks: 3,
      favorites: 20,
    },
    webPath: '/path/to/repo',
  },
  {
    id: 2,
    namespace: 'GitLab.org',
    group: 'GitLab',
    name: 'kubernetes-template',
    latestVersion: '2.2.1',
    description: 'A collection of tools for working with kubernetes.',
    icon: '🦊',
    lastUpdate: {
      time: '2023-03-19T18:19:04.537Z',
      user: {
        id: '2',
        name: 'user2',
        webUrl: 'path/to/user2',
      },
    },
    statistics: {
      forks: 0,
      favorites: 12,
    },
    webPath: '/path/to/repo',
  },
  {
    id: 3,
    namespace: 'GitLab.org',
    group: 'GitLab',
    name: 'ci-template',
    latestVersion: '1.3.4',
    description: 'A collection for working with GitLab CI templates.',
    icon: 'ci',
    lastUpdate: {
      time: '2023-02-06T19:47:43Z',
      user: {
        id: '3',
        name: 'user3',
        webUrl: 'path/to/user3',
      },
    },
    statistics: {
      forks: 0,
      favorites: 0,
    },
    webPath: '/path/to/repo',
  },
];
