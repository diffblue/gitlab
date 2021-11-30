export const getEscalationPoliciesQueryResponse = {
  data: {
    project: {
      id: '1',
      incidentManagementEscalationPolicies: {
        nodes: [
          {
            __typename: 'EscalationPolicyType',
            id: 'gid://gitlab/IncidentManagement::EscalationPolicy/25',
            name: 'Policy',
            description: 'Monitor policy description',
            rules: [
              {
                id: 'gid://gitlab/IncidentManagement::EscalationRule/35',
                status: 'ACKNOWLEDGED',
                elapsedTimeSeconds: 60,
                oncallSchedule: {
                  iid: '1',
                  name: 'Schedule',
                  __typename: 'IncidentManagementOncallSchedule',
                },
                user: null,
                __typename: 'EscalationRuleType',
              },
            ],
          },
        ],
      },
    },
  },
};

export const destroyPolicyResponse = {
  data: {
    escalationPolicyDestroy: {
      escalationPolicy: {
        __typename: 'EscalationPolicyType',
        id: 'gid://gitlab/IncidentManagement::EscalationPolicy/25',
        name: 'Policy',
        description: 'Monitor policy description',
        rules: [],
      },
      errors: [],
      __typename: 'EscalationPolicyDestroyPayload',
    },
  },
};

export const destroyPolicyResponseWithErrors = {
  data: {
    escalationPolicyDestroy: {
      escalationPolicy: {
        __typename: 'EscalationPolicyType',
        id: 'gid://gitlab/IncidentManagement::EscalationPolicy/25',
        name: 'Policy',
        description: 'Monitor policy description',
        rules: [],
      },
      errors: ['Ooh, somethigb went wrong!'],
      __typename: 'EscalationPolicyDestroyPayload',
    },
  },
};
