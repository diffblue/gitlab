import Vue from 'vue';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import initTree from '~/repository';
import CodeOwners from './components/code_owners.vue';

export default () => {
  const { router, data, apolloProvider, projectPath } = initTree();

  if (data.pathLocksAvailable) {
    const toggleBtn = document.querySelector('a.js-path-lock');

    if (!toggleBtn) return;

    toggleBtn.addEventListener('click', async (e) => {
      e.preventDefault();

      const { dataset } = e.target;
      const message =
        dataset.state === 'lock'
          ? __('Are you sure you want to lock this directory?')
          : __('Are you sure you want to unlock this directory?');

      const confirmed = await confirmAction(message);

      if (!confirmed) {
        return;
      }

      toggleBtn.setAttribute('disabled', 'disabled');

      axios
        .post(data.pathLocksToggle, {
          path: router.currentRoute.params.path.replace(/^\//, ''),
        })
        .then(() => window.location.reload())
        .catch(() => {
          toggleBtn.removeAttribute('disabled');
          createFlash({
            message: __('An error occurred while initializing path locks'),
          });
        });
    });
  }

  const initCodeOwnersApp = () =>
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

  initCodeOwnersApp();
};
