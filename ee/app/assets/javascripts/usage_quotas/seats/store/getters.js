export const tableItems = (state) => {
  return (state.members ?? []).map(({ email, ...member }) => ({
    user: {
      ...member,
      username: `@${member.username}`,
    },
    email,
  }));
};

export const isLoading = (state) =>
  state.isLoadingBillableMembers ||
  state.isLoadingGitlabSubscription ||
  state.isChangingMembershipState ||
  state.isRemovingBillableMember;
