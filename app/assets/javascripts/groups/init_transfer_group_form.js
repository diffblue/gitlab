import Vue from 'vue';
import { __ } from '~/locale';
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
