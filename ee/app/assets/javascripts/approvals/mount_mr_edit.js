import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import MrEditApp from './components/mr_edit/app.vue';
import createStore from './stores';
import mrEditModule from './stores/modules/mr_edit';

export default function mountApprovalInput(el) {
  if (!el) {
    return null;
  }

  const targetBranchTitle = document.querySelector('#js-target-branch-title');
  const targetBranch =
    targetBranchTitle?.dataset?.branchName ||
    targetBranchTitle?.textContent ||
    document.querySelector('#merge_request_target_branch')?.value;

  const store = createStore(
    { approvals: mrEditModule() },
    {
      ...el.dataset,
      prefix: 'mr-edit',
      canEdit: parseBoolean(el.dataset.canEdit),
      canUpdateApprovers: parseBoolean(el.dataset.canUpdateApprovers),
      showCodeOwnerTip: parseBoolean(el.dataset.showCodeOwnerTip),
      allowMultiRule: parseBoolean(el.dataset.allowMultiRule),
      canOverride: parseBoolean(el.dataset.canOverride),
    },
  );

  store.dispatch('setTargetBranch', targetBranch);

  return new Vue({
    el,
    store,
    render(h) {
      return h(MrEditApp);
    },
  });
}
