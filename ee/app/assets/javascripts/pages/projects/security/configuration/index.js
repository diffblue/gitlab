import { initSecurityConfiguration } from '~/security_configuration';

const el =
  document.querySelector('#js-security-configuration') ||
  document.querySelector('#js-security-configuration-static');

initSecurityConfiguration(el);
