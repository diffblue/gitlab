import { isInvalidPromoCodeError } from 'ee/subscriptions/new/utils';

describe('new subscription utils', () => {
  describe('isInvalidPromoCodeError', () => {
    [
      {
        errors: { message: 'Promo code is invalid', attributes: ['promo_code'], code: 'INVALID' },
        result: true,
      },
      {
        errors: { message: 'Quantity is invalid', attributes: ['quantity'], code: 'INVALID' },
        result: false,
      },
      { errors: { message: 'Error message', code: 'INVALID' }, result: false },
      { errors: { message: 'Error message', attributes: ['quantity'] }, result: false },
      { errors: 'Error', result: false },
      { errors: undefined, result: false },
    ].forEach((testCase) => {
      const { errors, result } = testCase;

      it(`returns ${result} for ${errors}`, () => {
        expect(isInvalidPromoCodeError(errors)).toBe(result);
      });
    });
  });
});
