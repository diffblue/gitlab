import { isSafeURL } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';

const i18n = {
  nameBlankError: s__("Geo|Site name can't be blank"),
  nameLengthError: s__('Geo|Site name should be between 1 and 255 characters'),
  urlBlankError: s__("Geo|URL can't be blank"),
  urlFormatError: s__('Geo|URL must be a valid url (ex: https://gitlab.com)'),
  capacityBlankError: s__("Geo|%{label} can't be blank"),
  capacityLengthError: s__('Geo|%{label} should be between 1-999'),
};

export const validateName = (data) => {
  if (!data) {
    return i18n.nameBlankError;
  } else if (data.length > 255) {
    return i18n.nameLengthError;
  }

  return '';
};

export const validateUrl = (data) => {
  if (!data) {
    return i18n.urlBlankError;
  } else if (!isSafeURL(data)) {
    return i18n.urlFormatError;
  }

  return '';
};

export const validateCapacity = ({ data, label }) => {
  if (!data && data !== 0) {
    return sprintf(i18n.capacityBlankError, { label });
  } else if (data < 1 || data > 999) {
    return sprintf(i18n.capacityLengthError, { label });
  }

  return '';
};
