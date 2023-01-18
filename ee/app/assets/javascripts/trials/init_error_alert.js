import Vue from 'vue';
import ErrorAlert from 'ee/trials/components/error_alert.vue';

export const initErrorAlert = () => {
  const el = document.querySelector('.js-error-alert');

  if (!el) {
    return null;
  }

  const { errors } = el.dataset;

  if (!errors) {
    return null;
  }

  return new Vue({
    el,
    name: 'ErrorAlertRoot',
    render(createElement) {
      return createElement(ErrorAlert, {
        props: { errors },
      });
    },
  });
};
