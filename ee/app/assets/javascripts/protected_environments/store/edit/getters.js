export const getUsersForRule = ({ usersForRules }) => ({ id }, ruleKey) => {
  return usersForRules[`${ruleKey}-${id}`] || [];
};
