import { guestOverageConfirmAction } from 'ee/members/guest_overage_confirm_action';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { MEMBER_ACCESS_LEVELS, GUEST_OVERAGE_MODAL_FIELDS } from 'ee/members/constants';
import * as createDefaultClient from '~/lib/graphql';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
const increaseOverageResponse = {
  data: {
    group: {
      gitlabSubscriptionsPreviewBillableUserChange: {
        willIncreaseOverage: true,
        newBillableUserCount: 2,
        seatsInSubscription: 1,
      },
    },
  },
};

const noBillableUserCountResponse = {
  data: {
    group: {
      gitlabSubscriptionsPreviewBillableUserChange: {
        willIncreaseOverage: true,
        seatsInSubscription: 1,
      },
    },
  },
};
const noSeatsInSubscriptionResponse = {
  data: {
    group: {
      gitlabSubscriptionsPreviewBillableUserChange: {
        willIncreaseOverage: true,
        newBillableUserCount: 1,
      },
    },
  },
};

const validGuestParams = {
  currentRoleValue: MEMBER_ACCESS_LEVELS.GUEST,
  newRoleValue: 30,
  newRoleName: 'Reporter',
  group: {
    name: 'GroupName',
    path: 'GroupPath/',
  },
  memberId: 1,
  memberType: 'user',
};

const validDevParams = {
  validGuestParams,
  currentRoleValue: 20,
};

describe('guestOverageConfirmAction', () => {
  beforeEach(() => {
    gon.features = {};
  });

  describe('when overage modal should not be shown', () => {
    describe('when showOverageOnRolePromotion feature flag is set to false', () => {
      beforeEach(() => {
        gon.features = { showOverageOnRolePromotion: false };
      });

      it('returns true', async () => {
        const confirmReturn = await guestOverageConfirmAction(validGuestParams);

        expect(confirmReturn).toBe(true);
      });
    });

    describe('when current access level is not guest', () => {
      it('returns true', async () => {
        const confirmReturn = await guestOverageConfirmAction(validDevParams);

        expect(confirmReturn).toBe(true);
      });
    });

    describe('when access is set to less than guest', () => {
      it('returns true', async () => {
        const params = {
          currentRoleValue: MEMBER_ACCESS_LEVELS.GUEST,
          newRoleValue: 5,
          newRoleName: 'Reporter',
          group: {
            name: 'GroupName',
            path: 'GroupPath/',
          },
          memberId: 1,
          memberType: 'user',
        };

        const confirmReturn = await guestOverageConfirmAction(params);

        expect(confirmReturn).toBe(true);
      });
    });

    describe.each([
      ['any data', null],
      ['defined seatsInSubscription', noSeatsInSubscriptionResponse],
      ['defined newBillableUserCount', noBillableUserCountResponse],
    ])('when query does not return %p', (name, resolvedValue) => {
      beforeEach(() => {
        createDefaultClient.default = jest.fn(() => ({
          query: jest.fn().mockResolvedValue(resolvedValue),
        }));
      });

      it('returns true', async () => {
        const confirmReturn = await guestOverageConfirmAction(validGuestParams);

        expect(confirmReturn).toBe(true);
      });
    });

    describe('when query returns valid overage response', () => {
      describe('when guestOverageConfirmAction params are invalid', () => {
        beforeEach(() => {
          createDefaultClient.default = jest.fn(() => ({
            query: jest.fn().mockResolvedValue(increaseOverageResponse),
          }));
        });

        it('returns true', async () => {
          const confirmReturn = await guestOverageConfirmAction();

          expect(confirmReturn).toBe(true);
        });
      });
    });
  });

  describe('when overage modal should be shown', () => {
    beforeEach(() => {
      gon.features = { showOverageOnRolePromotion: true };

      createDefaultClient.default = jest.fn(() => ({
        query: jest.fn().mockResolvedValue(increaseOverageResponse),
      }));

      guestOverageConfirmAction(validGuestParams);
    });

    it('calls confirmAction', () => {
      expect(confirmAction).toHaveBeenCalled();
    });

    describe('calls confirmAction with', () => {
      describe('modalHtmlMessage set with', () => {
        const overageData =
          increaseOverageResponse.data.group.gitlabSubscriptionsPreviewBillableUserChange;

        it('correct newBillableUserCount', () => {
          const newSeats = overageData.newBillableUserCount;
          expect(confirmAction).toHaveBeenCalledWith(
            '',
            expect.objectContaining({
              modalHtmlMessage: expect.stringContaining(`${newSeats}`),
            }),
          );
        });

        it('correct seatsInSubscription', () => {
          const currentSeats = overageData.seatsInSubscription;
          expect(confirmAction).toHaveBeenCalledWith(
            '',
            expect.objectContaining({
              modalHtmlMessage: expect.stringContaining(`${currentSeats}`),
            }),
          );
        });

        it('correct group name', () => {
          expect(confirmAction).toHaveBeenCalledWith(
            '',
            expect.objectContaining({
              modalHtmlMessage: expect.stringContaining(validGuestParams.group.name),
            }),
          );
        });
      });

      it('correct arguments', () => {
        expect(confirmAction).toHaveBeenCalledWith(
          '',
          expect.objectContaining({
            title: GUEST_OVERAGE_MODAL_FIELDS.TITLE,
            primaryBtnText: GUEST_OVERAGE_MODAL_FIELDS.CONTINUE_BUTTON_LABEL,
            cancelBtnText: GUEST_OVERAGE_MODAL_FIELDS.BACK_BUTTON_LABEL,
          }),
        );
      });
    });
  });
});
