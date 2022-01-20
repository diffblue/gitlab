import { isSafeURL } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';

export const validateName = (data) => {
  if (!data) {
    return s__("Geo|Site name can't be blank");
  } else if (data.length > 255) {
    return s__('Geo|Site name should be between 1 and 255 characters');
  }

  return '';
};

export const validateUrl = (data) => {
  if (!data) {
    return s__("Geo|URL can't be blank");
  } else if (!isSafeURL(data)) {
    return s__('Geo|URL must be a valid url (ex: https://gitlab.com)');
  }

  return '';
};

export const validateCapacity = ({ data, label }) => {
  if (!data && data !== 0) {
    return sprintf(s__("Geo|%{label} can't be blank"), { label });
  } else if (data < 1 || data > 999) {
    return sprintf(s__('Geo|%{label} should be between 1-999'), { label });
  }

  return '';
};
