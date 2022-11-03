import { testProviderName, testTrainingUrls } from 'jest/security_configuration/mock_data';
import {
  SECURITY_TRAINING_URL_STATUS_COMPLETED,
  SUPPORTED_IDENTIFIER_TYPE_CWE,
} from 'ee/vulnerabilities/constants';

export const testIdentifierName = 'cwe-1';

export const testIdentifiers = [
  { externalType: SUPPORTED_IDENTIFIER_TYPE_CWE, externalId: testIdentifierName },
  { externalType: 'cve', externalId: 'cve-1' },
];

export const generateNote = ({ id = 1295 } = {}) => ({
  __typename: 'Note',
  id: `gid://gitlab/DiscussionNote/${id}`,
  body: 'Created a note.',
  bodyHtml: '\u003cp\u003eCreated a note\u003c/p\u003e',
  updatedAt: '2021-08-25T16:21:18Z',
  system: false,
  systemNoteIconName: null,
  userPermissions: {
    adminNote: true,
  },
  author: {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    username: 'root',
    webPath: '/root',
  },
});

export const addTypenamesToDiscussion = (discussion) => {
  return {
    ...discussion,
    notes: {
      nodes: discussion.notes.nodes.map((n) => ({
        ...n,
        __typename: 'Note',
        author: {
          ...n.author,
          __typename: 'UserCore',
        },
      })),
    },
  };
};

const createSecurityTrainingUrls = ({ urlOverrides = {}, urls } = {}) =>
  urls || [
    {
      name: testProviderName[0],
      url: testTrainingUrls[0],
      status: SECURITY_TRAINING_URL_STATUS_COMPLETED,
      identifier: testIdentifierName,
      ...urlOverrides.first,
    },
    {
      name: testProviderName[1],
      url: testTrainingUrls[1],
      status: SECURITY_TRAINING_URL_STATUS_COMPLETED,
      identifier: testIdentifierName,
      ...urlOverrides.second,
    },
  ];

export const getSecurityTrainingProjectData = (urlOverrides = {}) => ({
  response: {
    data: {
      project: {
        id: 'gid://gitlab/Project/1',
        __typename: 'Project',
        securityTrainingUrls: createSecurityTrainingUrls(urlOverrides),
      },
    },
  },
});
