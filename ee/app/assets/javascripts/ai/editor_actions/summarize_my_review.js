import { __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import aiActionMutation from '../graphql/summarize_review.mutation.graphql';

export const createSummarizeMyReview = (store) => {
  return {
    title: __('Summarize my code review'),
    description: __('Creates a summary of all your draft code comments'),
    subscriptionVariables() {
      const resourceId = convertToGraphQLId('MergeRequest', store.state.notes.noteableData.id);
      return {
        userId: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
        resourceId,
      };
    },
    apolloMutation() {
      const resourceId = convertToGraphQLId('MergeRequest', store.state.notes.noteableData.id);
      return {
        mutation: aiActionMutation,
        variables: {
          resourceId,
        },
      };
    },
  };
};
