export const replicableTypeName = (state) => state.replicableType.split('_').join(' ');

export const hasFilters = (state) => Boolean(state.statusFilter || state.searchFilter);
