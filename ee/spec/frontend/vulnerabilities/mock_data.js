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
    {
      name: testProviderName[2],
      url: testTrainingUrls[2],
      status: SECURITY_TRAINING_URL_STATUS_COMPLETED,
      identifier: testIdentifierName,
      ...urlOverrides.third,
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

export const getVulnerabilityStatusMutationResponse = (queryName, expected) => ({
  data: {
    [queryName]: {
      errors: [],
      vulnerability: {
        id: 'gid://gitlab/Vulnerability/54',
        [`${expected}At`]: '2020-09-16T11:13:26Z',
        state: expected.toUpperCase(),
        ...(expected !== 'detected' && {
          [`${expected}By`]: {
            id: 'gid://gitlab/User/1',
          },
        }),
        stateTransitions: {
          nodes: [
            {
              dismissalReason: 'USED_IN_TESTS',
            },
          ],
        },
      },
    },
  },
});

export const dismissalDescriptions = {
  acceptable_risk:
    'The vulnerability is known, and has not been remediated or mitigated, but is considered to be an acceptable business risk.',
  false_positive:
    'An error in reporting in which a test result incorrectly indicates the presence of a vulnerability in a system when the vulnerability is not present.',
  mitigating_control:
    'A management, operational, or technical control (that is, safeguard or countermeasure) employed by an organization that provides equivalent or comparable protection for an information system.',
  used_in_tests: 'The finding is not a vulnerability because it is part of a test or is test data.',
  not_applicable:
    'The vulnerability is known, and has not been remediated or mitigated, but is considered to be in a part of the application that will not be updated.',
};
