export const tableItems = (state) => {
  return (state.members ?? []).map(({ email, ...member }) => ({
    user: {
      ...member,
      username: `@${member.username}`,
    },
    email,
  }));
};

export const membershipsById = (state) => (memberId) => {
  return state.userDetails[memberId] || { isLoading: true, items: [] };
};
