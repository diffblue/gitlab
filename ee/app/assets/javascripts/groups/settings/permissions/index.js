import Vue from 'vue';
import { __, s__ } from '~/locale';
import ConfirmModal from 'ee/groups/settings/permissions/components/confirm_modal.vue';

const confirmModalWrapperClassName = 'js-general-permissions-confirm-modal-wrapper';

const showConfirmModal = () => {
  const confirmModalWrapper = document.querySelector(`.${confirmModalWrapperClassName}`);
  const confirmModalElement = document.createElement('div');

  confirmModalWrapper.append(confirmModalElement);

  new Vue({
    render(createElement) {
      return createElement(ConfirmModal, {
        props: {
          modalOptions: {
            modalId: 'confirm-general-permissions-changes',
            title: s__('ApplicationSettings|Approve users in the pending approval status?'),
            text: s__(
              'ApplicationSettings|By making this change, you will automatically approve all users who are pending approval.',
            ),
            actionPrimary: {
              text: s__('ApplicationSettings|Approve users'),
            },
            actionCancel: {
              text: __('Cancel'),
            },
          },
        },
      });
    },
  }).$mount(confirmModalElement);
};

const shouldShowConfirmModal = (
  newUserSignupsCapOriginalValue,
  newUserSignupsCapNewValue,
  groupPermissionsForm,
) => {
  const isOldUserCapUnlimited = newUserSignupsCapOriginalValue === '';
  const isNewUserCapUnlimited = newUserSignupsCapNewValue === '';
  const hasUserCapChangedFromUnlimitedToLimited = isOldUserCapUnlimited && !isNewUserCapUnlimited;
  const hasUserCapChangedFromLimitedToUnlimited = !isOldUserCapUnlimited && isNewUserCapUnlimited;
  const hasModalBeenConfirmed = groupPermissionsForm.dataset.modalConfirmed === 'true';
  const shouldProceedWithSubmit = hasUserCapChangedFromUnlimitedToLimited || hasModalBeenConfirmed;

  if (shouldProceedWithSubmit) {
    return false;
  }

  return (
    hasUserCapChangedFromLimitedToUnlimited ||
    parseInt(newUserSignupsCapNewValue, 10) > parseInt(newUserSignupsCapOriginalValue, 10)
  );
};

const onGroupPermissionsFormSubmit = (event) => {
  const newUserSignupsCapInput = document.querySelector('#group_new_user_signups_cap');
  if (!newUserSignupsCapInput) {
    return;
  }
  const {
    dirtySubmitOriginalValue: newUserSignupsCapOriginalValue,
  } = newUserSignupsCapInput.dataset;

  if (
    shouldShowConfirmModal(
      newUserSignupsCapOriginalValue,
      newUserSignupsCapInput.value,
      event.target,
    )
  ) {
    event.preventDefault();
    event.stopImmediatePropagation();
    showConfirmModal();
  }
};

export const initGroupPermissionsFormSubmit = () => {
  const groupPermissionsForm = document.querySelector('.js-general-permissions-form');
  const confirmModalWrapper = document.createElement('div');

  confirmModalWrapper.className = confirmModalWrapperClassName;
  groupPermissionsForm.append(confirmModalWrapper);

  groupPermissionsForm.addEventListener('submit', onGroupPermissionsFormSubmit);
};
