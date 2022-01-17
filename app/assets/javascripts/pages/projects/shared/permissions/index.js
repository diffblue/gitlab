import Vue from 'vue';
import settingsPanel from './components/settings_panel.vue';

export default function initProjectPermissionsSettings() {
  const mountPoint = document.querySelector('.js-project-permissions-form');
  const componentPropsEl = document.querySelector('.js-project-permissions-form-data');
  const componentProps = JSON.parse(componentPropsEl.innerHTML);

  const {
    targetFormId,
    additionalInformation,
    confirmDangerMessage,
    confirmButtonText,
    phrase: confirmationPhrase,
  } = mountPoint.dataset;

  return new Vue({
    el: mountPoint,
    provide: {
      htmlConfirmationMessage: true,
      additionalInformation,
      confirmDangerMessage,
      confirmButtonText,
    },
    render: (createElement) =>
      createElement(settingsPanel, {
        props: {
          ...componentProps,
          confirmationPhrase,
        },
        on: {
          confirm: () => {
            if (targetFormId) document.getElementById(targetFormId)?.submit();
          },
        },
      }),
  });
}
