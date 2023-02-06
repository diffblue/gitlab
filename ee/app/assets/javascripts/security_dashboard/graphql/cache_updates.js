import produce from 'immer';

export function updateFindingState({ state, store, query, variables }) {
  const sourceData = store.readQuery({
    query,
    variables,
  });

  const newData = produce(sourceData, (draftData) => {
    draftData.project.pipeline.securityReportFinding.state = state;
  });

  store.writeQuery({
    query,
    variables,
    data: newData,
  });
}
