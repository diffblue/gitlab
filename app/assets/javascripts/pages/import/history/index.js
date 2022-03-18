import Vue from 'vue';
import ImportHistoryApp from './components/import_history_app.vue';

function mountImportHistoryApp(mountElement) {
  if (!mountElement) return undefined;

  return new Vue({
    el: mountElement,
    render(createElement) {
      return createElement(ImportHistoryApp);
    },
  });
}

mountImportHistoryApp(document.querySelector('#import-history-mount-element'));
