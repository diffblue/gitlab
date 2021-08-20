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
