export const codequalityIssues = (state) => {
  if (gon.features?.graphqlCodeQualityFullReport) {
    return state.codequalityIssues;
  }
  const { page, perPage } = state.pageInfo;
  const start = (page - 1) * perPage;
  return state.allCodequalityIssues.slice(start, start + perPage);
};

export const codequalityIssueTotal = (state) => {
  if (gon.features?.graphqlCodeQualityFullReport) {
    return state.pageInfo.count;
  }
  return state.allCodequalityIssues.length;
};
