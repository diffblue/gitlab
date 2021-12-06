import Vue from 'vue';
import CodeOwners from './code_owners.vue';

export default (projectPath, router, apolloProvider) =>
  new Vue({
    el: document.getElementById('js-code-owners'),
    router,
    apolloProvider,
    render(h) {
      return h(CodeOwners, {
        props: {
          filePath: this.$route.params.path,
          projectPath,
        },
      });
    },
  });
