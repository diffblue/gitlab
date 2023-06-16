import { uniqueId } from 'lodash';
import { slugify } from '~/lib/utils/text_utility';

const DEFAULT_EVENT = {
  action: 'Signed in with STANDARD authentication',
  date: '2020-03-18 12:04:23',
  ip_address: '127.0.0.1',
};

const populateEvent = (user, hasAuthorUrl = true, hasObjectUrl = true) => {
  const author = { name: user, url: null };
  const object = { name: user, url: null };
  const userSlug = slugify(user);

  if (hasAuthorUrl) {
    author.url = `/${userSlug}`;
  }

  if (hasObjectUrl) {
    object.url = `http://127.0.0.1:3000/${userSlug}`;
  }

  return {
    ...DEFAULT_EVENT,
    author,
    object,
    target: user,
  };
};

const verification = [
  'id5hzCbERzSkQ82tAs16tH5Y',
  'JsSQtg86au6buRtX9j98sYa8',
  'Cr28SHnrJtgpSXUEGfictGMS',
];

export default () => [
  populateEvent('User'),
  populateEvent('User 2', false),
  populateEvent('User 3', true, false),
  populateEvent('User 4', false, false),
];

export const mockExternalDestinationUrl = 'https://api.gitlab.com';
export const mockExternalDestinationHeader = () => ({
  id: uniqueId('gid://gitlab/AuditEvents::Streaming::Header/'),
  key: uniqueId('header-key-'),
  value: uniqueId('header-value-'),
});

const makeHeader = () => ({
  __typename: 'AuditEventStreamingHeader',
  id: `header-id-${uniqueId()}`,
  key: `header-key-${uniqueId()}`,
  value: 'header-value',
});

export const mockExternalDestinations = [
  {
    __typename: 'ExternalAuditEventDestination',
    id: 'test_id1',
    destinationUrl: mockExternalDestinationUrl,
    verificationToken: verification[0],
    headers: {
      nodes: [],
    },
    eventTypeFilters: [],
  },
  {
    __typename: 'ExternalAuditEventDestination',
    id: 'test_id2',
    destinationUrl: 'https://apiv2.gitlab.com',
    verificationToken: verification[1],
    eventTypeFilters: ['repository_download_operation', 'update_merge_approval_rule'],
    headers: {
      nodes: [makeHeader(), makeHeader()],
    },
  },
];

export const mockInstanceExternalDestinations = [
  {
    __typename: 'InstanceExternalAuditEventDestination',
    id: 'test_id1',
    destinationUrl: mockExternalDestinationUrl,
    verificationToken: verification[0],
  },
  {
    __typename: 'InstanceExternalAuditEventDestination',
    id: 'test_id2',
    destinationUrl: 'https://apiv2.gitlab.com',
    verificationToken: verification[1],
  },
];

export const groupPath = 'test-group';

export const instanceGroupPath = 'instance';

export const testGroupId = 'test-group-id';

export const destinationDataPopulator = (nodes) => ({
  data: {
    group: { id: testGroupId, externalAuditEventDestinations: { nodes } },
  },
});

export const instanceDestinationDataPopulator = (nodes) => ({
  data: {
    instanceExternalAuditEventDestinations: { nodes },
  },
});

export const destinationCreateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    externalAuditEventDestination: {
      __typename: 'ExternalAuditEventDestination',
      id: 'test-create-id',
      destinationUrl: mockExternalDestinationUrl,
      verificationToken: verification[2],
      group: {
        name: groupPath,
        id: testGroupId,
      },
      eventTypeFilters: null,
      headers: {
        nodes: [],
      },
    },
  };

  const errorData = {
    errors,
    externalAuditEventDestination: null,
  };

  return {
    data: {
      externalAuditEventDestinationCreate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const destinationDeleteMutationPopulator = (errors = []) => ({
  data: {
    externalAuditEventDestinationDestroy: {
      errors,
    },
  },
});

export const destinationHeaderCreateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersCreate: {
      errors,
      clientMutationId: uniqueId(),
      header: makeHeader(),
    },
  },
});

export const destinationHeaderUpdateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersUpdate: {
      errors,
      clientMutationId: uniqueId(),
      header: makeHeader(),
    },
  },
});

export const destinationHeaderDeleteMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersDestroy: {
      errors,
      clientMutationId: uniqueId(),
    },
  },
});

export const mockSvgPath = 'mock/path';

export const mockAuditEventDefinitions = [
  {
    event_name: 'repository_download_operation',
  },
  {
    event_name: 'update_merge_approval_rule',
  },
  {
    event_name: 'create_merge_approval_rule',
  },
  {
    event_name: 'project_unarchived',
  },
];
export const mockRemoveFilterSelect = ['repository_download_operation'];
export const mockRemoveFilterRemaining = ['update_merge_approval_rule'];
export const mockAddFilterSelect = [
  'repository_download_operation',
  'update_merge_approval_rule',
  'create_merge_approval_rule',
];
export const mockAddFilterRemaining = ['create_merge_approval_rule'];

export const mockStreamFiltersOptions = [
  { value: 'repository_download_operation', text: 'Repository download operation' },
  { value: 'update_merge_approval_rule', text: 'Update merge approval rule' },
  { value: 'create_merge_approval_rule', text: 'Create merge approval rule' },
  { value: 'project_unarchived', text: 'Project unarchived' },
];

export const destinationFilterRemoveMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingDestinationEventsRemove: {
      errors,
    },
  },
});

export const destinationFilterUpdateMutationPopulator = (errors = [], eventTypeFilters = []) => ({
  data: {
    auditEventsStreamingDestinationEventsAdd: {
      errors,
      eventTypeFilters,
    },
  },
});

export const destinationInstanceCreateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    instanceExternalAuditEventDestination: {
      __typename: 'InstanceExternalAuditEventDestination',
      id: 'test-create-id',
      destinationUrl: mockExternalDestinationUrl,
      verificationToken: verification[2],
      group: {
        name: groupPath,
        id: testGroupId,
      },
    },
  };

  const errorData = {
    errors,
    instanceExternalAuditEventDestination: null,
  };

  return {
    data: {
      instanceExternalAuditEventDestinationCreate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const destinationInstanceDeleteMutationPopulator = (errors = []) => ({
  data: {
    instanceExternalAuditEventDestinationDestroy: {
      errors,
    },
  },
});
