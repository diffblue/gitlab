import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
import stepListQuery from 'ee/vue_shared/purchase_flow/graphql/queries/step_list.query.graphql';
import resolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import typeDefs from 'ee/vue_shared/purchase_flow/graphql/typedefs.graphql';
import createDefaultClient from '~/lib/graphql';
import { STEPS } from '../constants';

function createClient(stepList) {
  const client = createDefaultClient(resolvers, {
    typeDefs,
  });

  client.cache.writeQuery({
    query: stepListQuery,
    data: {
      stepList,
    },
  });

  client.cache.writeQuery({
    query: activeStepQuery,
    data: {
      activeStep: stepList[0],
    },
  });

  return client;
}

export default createClient(STEPS);
