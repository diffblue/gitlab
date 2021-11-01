import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export default (externalIssuesQueryResolver) => {
  const resolvers = {
    Query: {
      externalIssues: externalIssuesQueryResolver,
    },
  };

  const defaultClient = createDefaultClient(resolvers);

  return new VueApollo({
    defaultClient,
  });
};
