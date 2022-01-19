import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import TransferGroupForm from './components/transfer_group_form.vue';

const prepareGroups = (rawGroups) => {
  const group = JSON.parse(rawGroups).map(({ id, text: humanName }) => ({
    id,
    humanName,
  }));

  return { group };
};

export default () => {
  const el = document.querySelector('.js-transfer-group-form');
  if (!el) {
    return false;
  }

  const {
    targetFormId = null,
    buttonText: confirmButtonText = '',
    phrase: confirmationPhrase = '',
    confirmDangerMessage = '',
    parentGroups = [],
    isPaidGroup,
    paidGroupHelpLink,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      confirmDangerMessage,
    },
    render(createElement) {
      return createElement(TransferGroupForm, {
        props: {
          parentGroups: prepareGroups(parentGroups),
          isPaidGroup: parseBoolean(isPaidGroup),
          paidGroupHelpLink,
          confirmButtonText,
          confirmationPhrase,
        },
        on: {
          confirm: () => {
            if (targetFormId) document.getElementById(targetFormId)?.submit();
          },
        },
      });
    },
  });
};
