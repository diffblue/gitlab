import { parseBoolean } from '~/lib/utils/common_utils';
import { initProjectSelects } from '~/vue_shared/components/entity_select/init_project_selects';

export const initDomainVerificationForm = () => {
  initProjectSelects();

  document.querySelectorAll('[name="pages_domain[auto_ssl_enabled]"]').forEach((input) => {
    input.addEventListener('change', (event) => {
      const isAutoSslEnabled = parseBoolean(event.target.value);
      document
        .querySelector('.js-shown-unless-auto-ssl')
        .classList.toggle('gl-display-none', isAutoSslEnabled);
      document
        .querySelector('.js-shown-if-auto-ssl')
        .classList.toggle('gl-display-none', !isAutoSslEnabled);
    });
  });
};
