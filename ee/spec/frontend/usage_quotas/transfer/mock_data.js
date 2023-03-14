export const getGroupDataTransferEgressResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/90',
      dataTransfer: {
        egressNodes: {
          nodes: [
            { date: '2023-01-01', totalEgress: '5000861558', __typename: 'EgressNode' },
            { date: '2023-02-01', totalEgress: '6651307793', __typename: 'EgressNode' },
            { date: '2023-03-01', totalEgress: '5368547376', __typename: 'EgressNode' },
            { date: '2023-04-01', totalEgress: '4055795925', __typename: 'EgressNode' },
          ],
          __typename: 'EgressNodeConnection',
        },
        __typename: 'GroupDataTransfer',
      },
      __typename: 'Group',
    },
  },
};
