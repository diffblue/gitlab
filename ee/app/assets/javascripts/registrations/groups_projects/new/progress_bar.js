import Vue from 'vue';
import ProgressBar from '../../components/progress_bar.vue';
import { STEPS, COMBINED_SIGNUP_FLOW_STEPS } from '../../constants';

export default function mountProgressBar() {
  const el = document.getElementById('progress-bar');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(ProgressBar, {
        props: { steps: COMBINED_SIGNUP_FLOW_STEPS, currentStep: STEPS.yourProject },
      });
    },
  });
}
