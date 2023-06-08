import mockQueryResponse from 'test_fixtures/graphql/oncall_schedules/graphql/queries/get_oncall_schedules_with_rotations_shifts.query.graphql.json';
import invalidUrl from '~/lib/utils/invalid_url';

const {
  data: {
    project: {
      incidentManagementOncallSchedules: {
        nodes: [
          {
            rotations: { nodes: mockRotations },
          },
        ],
      },
    },
  },
} = mockQueryResponse;

export { mockRotations };

export const scheduleIid = '37';

export const participants = [
  {
    id: '1',
    username: 'test',
    name: 'test',
    avatar: '',
    avatarUrl: '',
    webUrl: '',
  },
  {
    id: '2',
    username: 'hello',
    name: 'hello',
    avatar: '',
    avatarUrl: '',
    webUrl: '',
  },
];

export const errorMsg = 'Something went wrong';

const oncallScheduleInput = {
  __typename: 'IncidentManagementOncallSchedule',
  iid: '37',
  name: 'Test schedule',
  description: 'Description 1 lives here',
  timezone: 'Pacific/Honolulu',
  rotations: {
    nodes: [],
  },
};

export const getOncallSchedulesQueryResponse = {
  data: {
    project: {
      id: 'project-1',
      incidentManagementOncallSchedules: {
        nodes: [
          {
            ...oncallScheduleInput,
            name: 'Test schedule from query',
            timezone: 'America/Los_Angeles',
            rotations: { nodes: [{ id: 'gid://gitlab/IncidentManagement::OncallRotation/2' }] },
          },
        ],
      },
    },
  },
};

export const getOncallSchedulesQueryResponseWithRotations = {
  data: {
    project: {
      id: 'project-1',
      incidentManagementOncallSchedules: {
        nodes: [
          {
            ...oncallScheduleInput,
            name: 'Test schedule from query',
            timezone: 'America/Los_Angeles',
            rotations: { nodes: mockRotations },
          },
        ],
      },
    },
  },
};

export const destroyScheduleResponse = {
  data: {
    oncallScheduleDestroy: {
      errors: [],
      oncallSchedule: oncallScheduleInput,
    },
  },
};

export const destroyScheduleResponseWithErrors = {
  data: {
    oncallScheduleDestroy: {
      errors: ['Houston, we have a problem'],
      oncallSchedule: oncallScheduleInput,
    },
  },
};

export const updateScheduleResponse = {
  data: {
    oncallScheduleUpdate: {
      errors: [],
      oncallSchedule: {
        ...oncallScheduleInput,
        name: 'Test schedule 2',
        description: 'Description 2 lives here',
        rotations: { nodes: [mockRotations] },
      },
    },
  },
};

export const createScheduleResponse = {
  data: {
    oncallScheduleCreate: {
      errors: [],
      oncallSchedule: oncallScheduleInput,
    },
  },
};

export const createScheduleResponseWithErrors = {
  data: {
    oncallScheduleCreate: {
      errors: ['Houston, we have a problem'],
      oncallSchedule: {
        ...oncallScheduleInput,
      },
    },
  },
};

export const updateScheduleResponseWithErrors = {
  data: {
    oncallScheduleUpdate: {
      errors: ['Houston, we have a problem'],
      oncallSchedule: {
        ...oncallScheduleInput,
        name: 'Test schedule 2',
        description: 'Description 2 lives here',
        rotations: { nodes: [{ id: 'gid://gitlab/IncidentManagement::OncallRotation/2' }] },
      },
    },
  },
};

export const preExistingSchedule = {
  description: 'description',
  iid: '1',
  name: 'Monitor rotations',
  timezone: 'Pacific/Honolulu',
  rotations: {
    nodes: [],
  },
};

export const newlyCreatedSchedule = {
  description: 'description',
  iid: '2',
  name: 'S-Monitor rotations',
  timezone: 'Kyiv/EST',
  rotations: {
    nodes: [],
  },
};

export const createRotationResponse = {
  data: {
    oncallRotationCreate: {
      errors: [],
      oncallRotation: {
        id: '44',
        name: 'Test',
        startsAt: '2020-12-20T12:00:00Z',
        endsAt: '2021-03-17T12:00:00Z',
        length: 5,
        lengthUnit: 'WEEKS',
        activePeriod: {
          startTime: '02:00',
          endTime: '10:00',
        },
        participants: {
          nodes: [
            {
              id: '50',
              user: {
                id: 'gid://gitlab/User/50',
                username: 'project_1_bot3',
                avatarUrl: invalidUrl,
                avatar__typename: 'User',
                name: 'Bot 3',
              },
              colorWeight: '500',
              colorPalette: 'blue',
              __typename: 'OncallParticipantType',
            },
          ],
          __typename: 'OncallParticipantTypeConnection',
        },
        __typename: 'IncidentManagementOncallRotation',
      },
      __typename: 'OncallRotationCreatePayload',
    },
  },
};

export const createRotationResponseWithErrors = {
  data: {
    oncallRotationCreate: {
      errors: ['Houston, we have a problem'],
      oncallRotation: {
        id: '44',
        name: 'Test',
        startsAt: '2020-12-20T12:00:00Z',
        endsAt: '2021-03-17T12:00:00Z',
        length: 5,
        lengthUnit: 'WEEKS',
        activePeriod: {
          startTime: '02:00',
          endTime: '10:00',
        },
        participants: {
          nodes: [
            {
              id: '50',
              user: {
                id: 'gid://gitlab/User/50',
                username: 'project_1_bot3',
                avatarUrl: invalidUrl,
                __typename: 'User',
                name: 'Bot 3',
              },
              colorWeight: '500',
              colorPalette: 'blue',
              __typename: 'OncallParticipantType',
            },
          ],
          __typename: 'OncallParticipantTypeConnection',
        },
        __typename: 'IncidentManagementOncallRotation',
      },
      __typename: 'OncallRotationCreatePayload',
    },
  },
};

export const destroyRotationResponse = {
  data: {
    oncallRotationDestroy: {
      errors: [],
      oncallRotation: {
        __typename: 'IncidentManagementOncallRotation',
        ...mockRotations[0],
      },
    },
  },
};

export const destroyRotationResponseWithErrors = {
  data: {
    oncallRotationDestroy: {
      errors: ['Houston, we have a problem'],
      oncallRotation: {
        __typename: 'IncidentManagementOncallRotation',
        ...mockRotations[0],
      },
    },
  },
};
