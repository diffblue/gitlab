import $ from 'jquery';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { setCookie } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BurnCharts from './components/burn_charts.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  // handle hint dismissal
  const hint = $('.burndown-hint');
  hint.on('click', '.dismiss-icon', () => {
    hint.hide();
    setCookie('hide_burndown_message', 'true');
  });

  // generate burndown chart (if data available)
  const container = '.burndown-chart';
  const $chartEl = $(container);

  if ($chartEl.length) {
    const startDate = $chartEl.data('startDate');
    const dueDate = $chartEl.data('dueDate');
    const milestoneId = $chartEl.data('milestoneId');
    const burndownEventsPath = $chartEl.data('burndownEventsPath');
    const isLegacy = $chartEl.data('isLegacy');

    // eslint-disable-next-line no-new
    new Vue({
      el: container,
      components: {
        BurnCharts,
      },
      mixins: [glFeatureFlagsMixin()],
      apolloProvider,
      render(createElement) {
        return createElement('burn-charts', {
          props: {
            showNewOldBurndownToggle: isLegacy,
            burndownEventsPath,
            startDate,
            dueDate,
            milestoneId,
          },
        });
      },
    });
  }
};
