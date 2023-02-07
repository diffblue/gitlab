import createGqClient, { fetchPolicies } from '~/lib/graphql';

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

export const addIsChildEpicTrueProperty = (obj) => ({ ...obj, isChildEpic: true });

export const generateKey = (epic) => `${epic.isChildEpic ? 'child-epic-' : 'epic-'}${epic.id}`;

export const scrollToCurrentDay = (parentEl) => {
  const todayIndicatorEl = parentEl.querySelector('.js-current-day-indicator');
  if (todayIndicatorEl) {
    todayIndicatorEl.scrollIntoView({ block: 'nearest', inline: 'center' });
  }
};

/**
 * Returns transformed `filterParams` by congregating all `not` params into a
 * single object like { not: { labelName: [], ... }, authorUsername: '' }
 *
 * @param {Object} filterParams
 */
export const transformFetchEpicFilterParams = (filterParams) => {
  if (!filterParams) {
    return filterParams;
  }

  const newParams = {};

  Object.keys(filterParams).forEach((param) => {
    if (param.startsWith('not')) {
      // Get the param name like `authorUsername` from `not[authorUsername]`
      const key = param.match(/not\[(.+)\]/)[1];

      if (key) {
        newParams.not = newParams.not || {};
        newParams.not[key] = filterParams[param];
      }
    } else if (param.startsWith('or')) {
      // Get the param name like `authorUsername` from `not[authorUsername]`
      const key = param.match(/or\[(.+)\]/)[1];

      if (key) {
        newParams.or = newParams.or || {};
        newParams.or[key] = filterParams[param];
      }
    } else {
      newParams[param] = filterParams[param];
    }
  });

  return newParams;
};
