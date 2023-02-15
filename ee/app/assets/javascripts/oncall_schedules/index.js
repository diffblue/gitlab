import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import OnCallSchedulesWrapper from './components/oncall_schedules_wrapper.vue';
import apolloProvider from './graphql';
import getTimelineWidthQuery from './graphql/queries/get_timeline_width.query.graphql';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('#js-oncall_schedule');

  if (!el) return null;

  const {
    projectPath,
    emptyOncallSchedulesSvgPath,
    timezones,
    escalationPoliciesPath,
    userCanCreateSchedule,
    accessLevelDescriptionPath,
  } = el.dataset;

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getTimelineWidthQuery,
    data: {
      timelineWidth: 0,
    },
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      emptyOncallSchedulesSvgPath,
      timezones: JSON.parse(timezones),
      escalationPoliciesPath,
      userCanCreateSchedule: parseBoolean(userCanCreateSchedule),
      accessLevelDescriptionPath,
    },
    render(createElement) {
      return createElement(OnCallSchedulesWrapper);
    },
  });
};
