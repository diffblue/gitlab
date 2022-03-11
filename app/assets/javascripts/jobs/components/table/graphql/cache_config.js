import { isEqual, differenceWith } from 'lodash';

export default {
  typePolicies: {
    Project: {
      fields: {
        jobs: {
          keyArgs: false,
        },
      },
    },
    CiJobConnection: {
      merge(existing = {}, incoming, { args = {} }) {
        let nodes;

        if (Object.keys(existing).length !== 0 && isEqual(existing?.statuses, args?.statuses)) {
          const diff = differenceWith(existing.nodes, incoming.nodes, isEqual);
          if (existing.nodes.length === incoming.nodes.length) {
            if (diff.length !== 0) {
              nodes = [...existing.nodes, ...diff];
            } else {
              nodes = [...existing.nodes];
            }
          } else {
            nodes = [...existing.nodes, ...incoming.nodes];
          }
        } else {
          nodes = [...incoming.nodes];
        }

        return {
          nodes,
          statuses: Array.isArray(args.statuses) ? [...args.statuses] : args.statuses,
          pageInfo: incoming.pageInfo,
        };
      },
    },
  },
};
