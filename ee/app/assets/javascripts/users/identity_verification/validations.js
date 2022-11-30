import {
  I18N_PHONE_NUMBER_BLANK_ERROR,
  I18N_PHONE_NUMBER_NAN_ERROR,
  I18N_PHONE_NUMBER_LENGTH_ERROR,
  MAX_PHONE_NUMBER_LENGTH,
  I18N_VERIFICATION_CODE_BLANK_ERROR,
  I18N_VERIFICATION_CODE_NAN_ERROR,
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

export const validateVerificationCode = (code) => {
  if (!code && code !== 0) {
    return I18N_VERIFICATION_CODE_BLANK_ERROR;
  }

  if (code && Number.isNaN(Number(code))) {
    return I18N_VERIFICATION_CODE_NAN_ERROR;
  }

  return '';
};
