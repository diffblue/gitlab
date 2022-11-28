import {
  I18N_PHONE_NUMBER_BLANK_ERROR,
  I18N_PHONE_NUMBER_NAN_ERROR,
  I18N_PHONE_NUMBER_LENGTH_ERROR,
  MAX_PHONE_NUMBER_LENGTH,
} from './constants';

export const validatePhoneNumber = (phoneNumber) => {
  if (!phoneNumber && phoneNumber !== 0) {
    return I18N_PHONE_NUMBER_BLANK_ERROR;
  }

  const numbersOnlyRegex = /^[0-9]+$/;
  if (!numbersOnlyRegex.test(phoneNumber)) {
    return I18N_PHONE_NUMBER_NAN_ERROR;
  }

  if (phoneNumber.length > MAX_PHONE_NUMBER_LENGTH) {
    return I18N_PHONE_NUMBER_LENGTH_ERROR;
  }

  return '';
};
