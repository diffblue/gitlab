import '~/pages/projects/settings/merge_requests';
import Vue from 'vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import mountApprovals from 'ee/approvals/mount_project_settings';
import { initMergeOptionSettings } from 'ee/pages/projects/edit/merge_options';
import { initMergeRequestMergeChecksApp } from 'ee/merge_checks';
import mountStatusChecks from 'ee/status_checks/mount';

function initRefSwitcher() {
  const refSwitcherEl = document.getElementById('js-target-branch');

  if (!refSwitcherEl) return false;

  const { projectId } = refSwitcherEl.dataset;

  return new Vue({
    el: refSwitcherEl,
    render(createElement) {
      return createElement(RefSelector, {
        props: {
          projectId,
          value: '',
          useSymbolicRefNames: true,
          queryParams: { sort: 'updated_desc' },
          enabledRefTypes: ['REF_TYPE_BRANCHES'],
        },
        on: {
          input(selectedRef) {
            document.getElementById(
              'projects_target_branch_rule_target_branch',
            ).value = selectedRef.replace(/^refs\/(tags|heads)\//, '');
          },
        },
      });
    },
  });
}

mountApprovals(document.getElementById('js-mr-approvals-settings'));
mountStatusChecks(document.getElementById('js-status-checks-settings'));

initMergeOptionSettings();
initMergeRequestMergeChecksApp();

requestIdleCallback(() => {
  initRefSwitcher();
});
