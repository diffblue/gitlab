import Vue from 'vue';
import Verification from './components/verification.vue';

export default () => {
  const el = document.querySelector('.js-registration-verification');

  if (!el) {
    return false;
  }

  const { nextStepUrl } = el.dataset;

  return new Vue({
    el,
    provide: { nextStepUrl },
    render(createElement) {
      return createElement(Verification);
    },
  });
};
