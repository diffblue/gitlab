import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import { __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';

export const summarizeCommentsAction = (resourceGlobalId) => ({
  title: __('Summarize comments'),
  description: __('Creates a summary of all comments'),
  subscriptionVariables() {
    return {
      userId: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
      resourceId: resourceGlobalId,
    };
  },
  apolloMutation() {
    return {
      mutation: aiActionMutation,
      variables: {
        input: {
          summarizeComments: {
            resourceId: resourceGlobalId,
          },
        },
      },
    };
  },
});
