import {
  INVALID_PROMO_CODE_ERROR_CODE,
  PROMO_CODE_ERROR_ATTRIBUTE,
} from 'ee/subscriptions/new/constants';

export const isInvalidPromoCodeError = (errors) => {
  if (!errors || typeof errors !== 'object') {
    return false;
  }

  const { attributes = [], code } = errors;

  return attributes.includes(PROMO_CODE_ERROR_ATTRIBUTE) && code === INVALID_PROMO_CODE_ERROR_CODE;
};
