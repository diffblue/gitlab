import mountApprovals from 'ee/approvals/mount_mr_edit';
import mountApprovalsPromo from 'ee/approvals/mount_mr_promo';
import mountBlockingMergeRequestsInput from 'ee/projects/merge_requests/blocking_mr_input';
import initCheckFormState from '~/pages/projects/merge_requests/edit/check_form_state';

export default () => {
  const editMrApp = mountApprovals(document.getElementById('js-mr-approvals-input'));
  mountApprovalsPromo(document.getElementById('js-mr-approvals-promo'));
  mountBlockingMergeRequestsInput(document.getElementById('js-blocking-merge-requests-input'));

  if (editMrApp) {
    editMrApp.$on('hidden-inputs-mounted', initCheckFormState);
  }
};
