import { makeEntities } from '../helpers';

export const sastCiConfigurationQueryResponse = {
  data: {
    project: {
      id: '1',
      sastCiConfiguration: {
        global: {
          nodes: makeEntities(2, { __typename: 'SastCiConfigurationEntity' }),
          __typename: 'SastCiConfigurationEntityConnection',
        },
        pipeline: {
          nodes: makeEntities(2, { __typename: 'SastCiConfigurationEntity' }),
          __typename: 'SastCiConfigurationEntityConnection',
        },
        analyzers: {
          nodes: [
            {
              description: 'Ruby on Rails',
              enabled: false,
              label: 'Brakeman',
              name: 'brakeman',
              variables: {
                nodes: makeEntities(2, { __typename: 'SastCiConfigurationEntity' }),
                __typename: 'SastCiConfigurationEntityConnection',
              },
              __typename: 'SastCiConfigurationAnalyzersEntity',
            },
            {
              description: 'Python',
              enabled: false,
              label: 'Bandit',
              name: 'bandit',
              variables: {
                nodes: [],
                __typename: 'SastCiConfigurationEntityConnection',
              },
              __typename: 'SastCiConfigurationAnalyzersEntity',
            },
          ],
          __typename: 'SastCiConfigurationAnalyzersEntityConnection',
        },
        __typename: 'SastCiConfiguration',
      },
      __typename: 'Project',
    },
  },
};
