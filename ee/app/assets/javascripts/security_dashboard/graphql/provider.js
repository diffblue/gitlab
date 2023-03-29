import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { relayStylePagination } from '@apollo/client/utilities';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);
// Please see this comment for an explanation of what this does:
// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86408#note_942523549
export const cacheConfig = {
  typePolicies: {
    Group: {
      fields: {
        projects: relayStylePagination(['includeSubgroups', 'ids', 'search']),
      },
    },
    InstanceSecurityDashboard: {
      fields: {
        projects: relayStylePagination(['search']),
      },
    },
  },
};

export const defaultClient = createDefaultClient({}, { cacheConfig });

export default new VueApollo({ defaultClient });
