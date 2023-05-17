import Vue from 'vue';
import GroupActivityCard from './components/group_activity_card.vue';

export default () => {
  const container = document.getElementById('js-group-activity');

  if (!container) return;

  const {
    groupFullPath,
    groupName,
    mergeRequestsMetricLink,
    issuesMetricLink,
    newMembersMetricLink,
  } = container.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: container,
    provide: {
      groupFullPath,
      groupName,
      mergeRequestsMetricLink,
      issuesMetricLink,
      newMembersMetricLink,
    },
    render(h) {
      return h(GroupActivityCard);
    },
  });
};
