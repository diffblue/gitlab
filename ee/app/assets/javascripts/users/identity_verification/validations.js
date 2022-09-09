import {
  PHONE_NUMBER_BLANK_ERROR,
  PHONE_NUMBER_NAN_ERROR,
  MAX_PHONE_NUMBER_LENGTH,
  PHONE_NUMBER_LENGTH_ERROR,
} from './constants';

export const validatePhoneNumber = (phoneNumber) => {
  if (!phoneNumber && phoneNumber !== 0) {
    return PHONE_NUMBER_BLANK_ERROR;
  }

  const numbersOnlyRegex = /^[0-9]+$/;
  if (!numbersOnlyRegex.test(phoneNumber)) {
    return PHONE_NUMBER_NAN_ERROR;
  }

  if (phoneNumber.length > MAX_PHONE_NUMBER_LENGTH) {
    return PHONE_NUMBER_LENGTH_ERROR;
  }

  return '';
};
