import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';

export const mockResourceLinks = [
  {
    id: 'gid://gitlab/IncidentManagement::IssuableResourceLink/1',
    link: `${DOCS_URL}/incident-info`,
    linkType: 'zoom',
    linkText: 'Doclink for incident',
  },
  {
    id: 'gid://gitlab/IncidentManagement::IssuableResourceLink/2',
    link: `${DOCS_URL}/incident-info2`,
    linkType: 'zoom',
    linkText: 'Doclink for incident 2',
  },
  {
    id: 'gid://gitlab/IncidentManagement::IssuableResourceLink/3',
    link: `${DOCS_URL}/incident-info3`,
    linkType: 'zoom',
    linkText: 'Doclink for incident 3',
  },
];

export const resourceLinksListResponse = {
  data: {
    issue: {
      id: 'gid://gitlab/Issue/455',
      issuableResourceLinks: {
        nodes: mockResourceLinks,
      },
    },
  },
};

export const resourceLinksEmptyResponse = {
  data: {
    issue: {
      id: 'gid://gitlab/Issue/456',
      issuableResourceLinks: {
        nodes: [],
      },
    },
  },
};

const resourceLinkDeleteData = (errors = []) => {
  return {
    data: {
      issuableResourceLinkDestroy: {
        issuableResourceLink: { ...mockResourceLinks[0] },
        errors,
      },
    },
  };
};

const resourceLinkCreateData = (errors = []) => {
  return {
    data: {
      issuableResourceLinkCreate: {
        issuableResourceLink: { ...mockResourceLinks[0] },
        errors,
      },
    },
  };
};

export const resourceLinksDeleteEventResponse = resourceLinkDeleteData();

export const resourceLinkDeleteEventError = resourceLinkDeleteData(['Item does not exist']);

export const resourceLinkCreateEventResponse = resourceLinkCreateData();

export const resourceLinkCreateEventError = resourceLinkCreateData(['Create error']);
