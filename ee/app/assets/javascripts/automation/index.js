import Vue from 'vue';
import AutomationApp from './automation_app.vue';

export default () => {
  const el = document.getElementById('js-automation');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(h) {
      return h(AutomationApp);
    },
  });
};
