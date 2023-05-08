import produce from 'immer';
import userWorkspacesQuery from '../graphql/queries/user_workspaces_list.query.graphql';
import { WORKSPACES_LIST_PAGE_SIZE } from '../constants';

export const addWorkspace = (store, workspace) => {
  store.updateQuery(
    {
      query: userWorkspacesQuery,
      variables: { after: null, before: null, first: WORKSPACES_LIST_PAGE_SIZE },
    },
    (sourceData) =>
      produce(sourceData, (draftData) => {
        // If there's nothing in the query we don't really need to update it. It should just refetch naturally.
        if (!draftData) {
          return;
        }

        draftData.currentUser.workspaces.nodes.unshift(workspace);
      }),
  );
};
