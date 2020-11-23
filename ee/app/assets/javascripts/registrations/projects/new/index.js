import Vue from 'vue';
import ProgressBar from '../../components/progress_bar.vue';
import { STEPS, ONBOARDING_ISSUES_EXPERIMENT_FLOW_STEPS } from '../../constants';

export default () => {
  const el = document.getElementById('progress-bar');

  if (!el) return null;

  return new Vue({
    el,
    render(createElement) {
      return createElement(ProgressBar, {
        props: { steps: ONBOARDING_ISSUES_EXPERIMENT_FLOW_STEPS, currentStep: STEPS.yourProject },
      });
    },
  });
};
