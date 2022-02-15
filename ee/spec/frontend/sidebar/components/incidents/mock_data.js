export const mockEscalationPolicy1 = {
  __typename: 'EscalationPolicyType',
  id: 'gid://gitlab/IncidentManagement::EscalationPolicy/1',
  title: 'First policy',
};

export const mockEscalationPolicy2 = {
  __typename: 'EscalationPolicyType',
  id: 'gid://gitlab/IncidentManagement::EscalationPolicy/2',
  title: 'Second policy',
};

export const mockEscalationPoliciesResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      attributes: {
        nodes: [mockEscalationPolicy1, mockEscalationPolicy2],
        __typename: 'EscalationPolicyTypeConnection',
      },
    },
  },
};

export const mockCurrentEscalationPolicyResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/1',
        attribute: mockEscalationPolicy1,
        escalationStatus: 'ACKNOWLEDGED',
      },
    },
  },
};

export const mockNullEscalationPolicyResponse = {
  data: {
    workspace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      issuable: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/1',
        attribute: null,
        escalationStatus: 'TRIGGERED',
      },
    },
  },
};
