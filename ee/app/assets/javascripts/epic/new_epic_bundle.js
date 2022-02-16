import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import EpicForm from './components/epic_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export function initEpicForm() {
  const el = document.querySelector('.js-epic-new');

  if (!el) {
    return null;
  }

  const {
    groupPath,
    groupEpicsPath,
    labelsManagePath,
    markdownDocsPath,
    markdownPreviewPath,
  } = el.dataset;

  return new Vue({
    el,
    name: 'EpicCreateRoot',
    apolloProvider,
    provide: {
      groupPath,
      fullPath: groupPath,
      allowLabelCreate: true,
      groupEpicsPath,
      labelsManagePath,
      markdownDocsPath,
      markdownPreviewPath,
    },
    render(createElement) {
      return createElement(EpicForm);
    },
  });
}
