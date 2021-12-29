import { produce } from 'immer';

export const removeProfile = ({ profileId, store, queryBody }) => {
  const sourceData = store.readQuery(queryBody);

  const data = produce(sourceData, (draftState) => {
    draftState.project.pipelines.nodes = draftState.project.pipelines.nodes.filter(({ id }) => {
      return id !== profileId;
    });
  });

  store.writeQuery({ ...queryBody, data });
};
