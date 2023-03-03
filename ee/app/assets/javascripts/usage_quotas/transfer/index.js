import Vue from 'vue';
import GroupTransferApp from './components/group_transfer_app.vue';

export const initGroupTransferApp = () => {
  const el = document.getElementById('js-group-transfer-app');

  if (!el) return false;

  const { fullPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(GroupTransferApp);
    },
  });
};
