import { guestOverageConfirmAction } from 'ee/members/guest_overage_confirm_action';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { MEMBER_ACCESS_LEVELS, GUEST_OVERAGE_MODAL_FIELDS } from 'ee/members/constants';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('guestOverageConfirmAction', () => {
  let originalGon;

  beforeAll(() => {
    originalGon = window.gon;
  });

  afterEach(() => {
    window.gon = originalGon;
  });

  describe('when overage modal should not be shown', () => {
    describe('when showOverageOnRolePromotion feature flag is set to false', () => {
      beforeEach(() => {
        gon.features = { showOverageOnRolePromotion: false };
      });

      it('returns true', async () => {
        const confirmReturn = await guestOverageConfirmAction({
          currentAccessIntValue: 20,
          dropdownIntValue: 30,
        });

        expect(confirmReturn).toBe(true);
      });
    });

    describe('when current access level is not guest', () => {
      it('returns true', async () => {
        const confirmReturn = await guestOverageConfirmAction({
          currentAccessIntValue: 20,
          dropdownIntValue: 30,
        });

        expect(confirmReturn).toBe(true);
      });
    });

    describe('when access is set to less than guest', () => {
      it('returns true', async () => {
        const confirmReturn = await guestOverageConfirmAction({
          currentAccessIntValue: MEMBER_ACCESS_LEVELS.GUEST,
          dropdownIntValue: 5,
        });

        expect(confirmReturn).toBe(true);
      });
    });
  });

  describe('when overage modal should be shown', () => {
    beforeEach(() => {
      gon.features = { showOverageOnRolePromotion: true };
      guestOverageConfirmAction({
        currentAccessIntValue: MEMBER_ACCESS_LEVELS.GUEST,
        dropdownIntValue: 30,
      });
    });

    it('calls confirmAction with expected arguments', () => {
      expect(confirmAction).toHaveBeenCalledWith('', {
        title: GUEST_OVERAGE_MODAL_FIELDS.TITLE,
        modalHtmlMessage: expect.any(String),
        primaryBtnText: GUEST_OVERAGE_MODAL_FIELDS.CONTINUE_BUTTON_LABEL,
        cancelBtnText: GUEST_OVERAGE_MODAL_FIELDS.BACK_BUTTON_LABEL,
      });
    });
  });
});
