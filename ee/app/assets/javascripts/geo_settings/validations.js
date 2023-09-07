import validateIpAddress from 'ee/validators/ip_address';
import { s__ } from '~/locale';

const i18n = {
  timeoutBlankError: s__("Geo|Connection timeout can't be blank"),
  timeoutNanError: s__('Geo|Connection timeout must be a number'),
  timeoutLengthError: s__('Geo|Connection timeout should be between 1-120'),
  allowedIpBlankError: s__("Geo|Allowed Geo IP can't be blank"),
  allowedIpLengthError: s__('Geo|Allowed Geo IP should be between 1 and 255 characters'),
  allowedIpFormatError: s__('Geo|Allowed Geo IP should contain valid IP addresses'),
};

const validateIP = (data) => {
  let addresses = data.replace(/\s/g, '').split(',');

  addresses = addresses.map((address) => validateIpAddress(address));

  return !addresses.some((a) => !a);
};

export const validateTimeout = (data) => {
  if (!data && data !== 0) {
    return i18n.timeoutBlankError;
  }
  if (data && Number.isNaN(Number(data))) {
    return i18n.timeoutNanError;
  }
  if (data < 1 || data > 120) {
    return i18n.timeoutLengthError;
  }

  return '';
};

export const validateAllowedIp = (data) => {
  if (!data) {
    return i18n.allowedIpBlankError;
  }
  if (data.length > 255) {
    return i18n.allowedIpLengthError;
  }
  if (!validateIP(data)) {
    return i18n.allowedIpFormatError;
  }

  return '';
};
