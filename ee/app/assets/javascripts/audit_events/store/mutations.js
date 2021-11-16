import * as types from './mutation_types';

export default {
  [types.INITIALIZE_AUDIT_EVENTS](
    state,
    {
      entity_id: entityId = null,
      entity_username: entityUsername = null,
      author_username: authorUsername = null,
      entity_type: type = null,
      created_after: startDate = null,
      created_before: endDate = null,
      sort: sortBy = null,
    } = {},
  ) {
    const data = entityId ?? entityUsername ?? authorUsername;
    state.filterValue = type && data ? [{ type, value: { data, operator: '=' } }] : [];
    state.startDate = startDate;
    state.endDate = endDate;
    state.sortBy = sortBy;
  },

  [types.SET_FILTER_VALUE](state, filterValue) {
    state.filterValue = filterValue;
  },

  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },

  [types.SET_SORT_BY](state, sortBy) {
    state.sortBy = sortBy;
  },
};
