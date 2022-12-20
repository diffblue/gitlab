import { sprintf } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import {
  GUEST_OVERAGE_MODAL_FIELDS,
  MEMBER_ACCESS_LEVELS,
  overageModalInfoText,
  overageModalInfoWarning,
} from './constants';

const shouldShowOverageModal = (currentAccessIntValue, dropdownValue) => {
  if (
    currentAccessIntValue === MEMBER_ACCESS_LEVELS.GUEST &&
    dropdownValue > MEMBER_ACCESS_LEVELS.GUEST
  ) {
    return true;
  }

  return false;
};

const getConfirmContent = ({ subscriptionSeats, totalUsers, groupName }) => {
  const infoText = overageModalInfoText(subscriptionSeats);
  const infoWarning = overageModalInfoWarning(totalUsers, groupName);
  const link = sprintf(
    GUEST_OVERAGE_MODAL_FIELDS.LINK_TEXT,
    {
      linkStart: `<a href="${GUEST_OVERAGE_MODAL_FIELDS.LINK}" target="_blank">`,
      linkEnd: '</a>',
    },
    false,
  );

  return `${infoText} ${infoWarning} ${link}`;
};

export const guestOverageConfirmAction = async ({
  currentAccessIntValue,
  dropdownIntValue,
  subscriptionSeats = 0,
  totalUsers = 0,
  groupName = '',
} = {}) => {
  if (
    !gon.features.showOverageOnRolePromotion ||
    !shouldShowOverageModal(currentAccessIntValue, dropdownIntValue)
  ) {
    return true;
  }

  const confirmContent = getConfirmContent({ subscriptionSeats, totalUsers, groupName });

  return confirmAction('', {
    title: GUEST_OVERAGE_MODAL_FIELDS.TITLE,
    modalHtmlMessage: confirmContent,
    primaryBtnText: GUEST_OVERAGE_MODAL_FIELDS.CONTINUE_BUTTON_LABEL,
    cancelBtnText: GUEST_OVERAGE_MODAL_FIELDS.BACK_BUTTON_LABEL,
  });
};
