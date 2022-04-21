import Vue from 'vue';
import FlashAlert from 'ee/trials/components/flash_alert.vue';

export const initFlashAlert = () => {
  const el = document.querySelector('.js-flash-alert');

  if (!el) {
    return null;
  }

  const { errors } = el.dataset;

  if (!errors) {
    return null;
  }

  return new Vue({
    el,
    name: 'FlashAlertRoot',
    render(createElement) {
      return createElement(FlashAlert, {
        props: { errors },
      });
    },
  });
};
