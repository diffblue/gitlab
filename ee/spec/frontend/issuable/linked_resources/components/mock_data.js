export const mockResourceLinks = [
  {
    id: 'gid://gitlab/IncidentManagement::IssuableResourceLink/1',
    issue: {
      id: 'gid://gitlab/Issue/455',
      title: 'Demo incident',
    },
    link: 'http://docs.gitlab.com/incident-info',
    linkType: 'zoom',
    linkText: 'Doclink for incident',
  },
  {
    id: 'gid://gitlab/IncidentManagement::IssuableResourceLink/2',
    issue: {
      id: 'gid://gitlab/Issue/455',
      title: 'Demo incident',
    },
    link: 'http://docs.gitlab.com/incident-info2',
    linkType: 'zoom',
    linkText: 'Doclink for incident 2',
  },
  {
    id: 'gid://gitlab/IncidentManagement::IssuableResourceLink/3',
    issue: {
      id: 'gid://gitlab/Issue/455',
      title: 'Demo incident',
    },
    link: 'http://docs.gitlab.com/incident-info3',
    linkType: 'zoom',
    linkText: 'Doclink for incident 3',
  },
];

export const resourceLinksListResponse = {
  data: {
    issue: {
      issuableResourceLinks: {
        nodes: mockResourceLinks,
      },
    },
  },
};

export const resourceLinksEmptyResponse = {
  data: {
    issue: {
      issuableResourceLinks: {
        nodes: [],
      },
    },
  },
};
