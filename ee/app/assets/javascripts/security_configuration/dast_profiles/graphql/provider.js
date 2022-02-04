import { concatPagination } from '@apollo/client/utilities';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const profilesCachePolicy = () => ({
  keyArgs: ['fullPath'],
});

const profilesPagination = () => ({
  fields: {
    nodes: concatPagination(),
  },
});

export default new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      cacheConfig: {
        typePolicies: {
          Project: {
            fields: {
              dastSiteProfiles: profilesCachePolicy(),
              dastScannerProfiles: profilesCachePolicy(),
            },
          },
          DastSiteProfileConnection: profilesPagination(),
          DastScannerProfileConnection: profilesPagination(),
        },
      },
    },
  ),
});
