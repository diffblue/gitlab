export const codequalityIssues = (state) => {
  const { page, perPage } = state.pageInfo;
  const start = (page - 1) * perPage;
  return state.allCodequalityIssues.slice(start, start + perPage);
};

export const codequalityIssueTotal = (state) => state.allCodequalityIssues.length;
