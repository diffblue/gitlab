import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Api from 'ee/api';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { PER_PAGE } from './constants';

Vue.use(VueApollo);

export const createResolvers = (groupId) => ({
  Query: {
    groups(_, { search }) {
      const url = groupId
        ? Api.buildUrl(Api.subgroupsPath).replace(':id', groupId)
        : Api.buildUrl(Api.groupsPath);
      const params = {
        per_page: PER_PAGE,
        search,
      };

      return axios.get(url, { params }).then(({ data }) => {
        const groups = {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          __typename: 'Groups',
          // eslint-disable-next-line @gitlab/require-i18n-strings
          nodes: data.map((group) => ({ ...group, __typename: 'Group' })),
        };

        return groups;
      });
    },
  },
});

export const createApolloProvider = (groupId) =>
  new VueApollo({
    defaultClient: createDefaultClient(createResolvers(groupId)),
  });
