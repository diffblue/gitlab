import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionDetailsUserInfo, {
  billableUsersURL,
  trueUpURL,
  i18n,
} from 'ee/admin/subscriptions/show/components/subscription_details_user_info.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { license } from '../mock_data';

describe('Subscription Details User Info', () => {
  let wrapper;

  const itif = (condition) => (condition ? it : it.skip);
  const findSubscriptionText = () =>
    wrapper.findByTestId('users-in-subscription').find('h2').text();

  const createComponent = (props = {}, stubGlSprintf = false) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionDetailsUserInfo, {
        propsData: {
          subscription: { ...license.ULTIMATE, plan: 'premium' },
          ...props,
        },
        stubs: {
          GlCard,
          GlSprintf: stubGlSprintf ? GlSprintf : true,
        },
      }),
    );
  };

  const findUsersInSubscriptionCard = () =>
    wrapper.findComponent('[data-testid="users-in-subscription"]');

  const findUsersInSubscriptionDesc = () =>
    findUsersInSubscriptionCard().findComponent('[data-testid="users-in-subscription-desc"]');

  describe.each`
    testId                  | info   | title                              | text                              | link
    ${'billable-users'}     | ${'8'} | ${i18n.billableUsersTitle}         | ${i18n.billableUsersText}         | ${billableUsersURL}
    ${'maximum-users'}      | ${'8'} | ${i18n.maximumUsersTitle}          | ${i18n.maximumUsersText}          | ${false}
    ${'users-over-license'} | ${'0'} | ${i18n.usersOverSubscriptionTitle} | ${i18n.usersOverSubscriptionText} | ${trueUpURL}
  `('with data for $card', ({ testId, info, title, text, link }) => {
    beforeEach(() => {
      createComponent();
    });

    const findUseCard = () => wrapper.findByTestId(testId);

    it('displays the info', () => {
      expect(findUseCard().find('h2').text()).toBe(info);
    });

    it('displays the title', () => {
      expect(findUseCard().find('h5').text()).toBe(title);
    });

    itif(link)(`displays the content with a link`, () => {
      // eslint-disable-next-line jest/no-standalone-expect
      expect(findUseCard().findComponent(GlSprintf).attributes('message')).toBe(text);
    });

    itif(link)(`has a link`, () => {
      createComponent({}, true);
      // eslint-disable-next-line jest/no-standalone-expect
      expect(findUseCard().findComponent(GlLink).attributes('href')).toBe(link);
    });

    itif(!link)(`has not a link`, () => {
      createComponent({}, true);
      // eslint-disable-next-line jest/no-standalone-expect
      expect(findUseCard().findComponent(GlLink).exists()).toBe(link);
    });
  });

  describe('Users is subscription', () => {
    it('should display the value when present', () => {
      const subscription = { ...license.ULTIMATE, usersInLicenseCount: 0, plan: 'premium' };
      createComponent({ subscription });

      expect(findSubscriptionText()).toBe('0');
    });

    it('should display Unlimited when users in license is null', () => {
      const subscription = { ...license.ULTIMATE, usersInLicenseCount: null, plan: 'premium' };
      createComponent({ subscription });

      expect(findSubscriptionText()).toBe('Unlimited');
    });

    it('does not render card description', () => {
      const subscription = { ...license.ULTIMATE, usersInLicenseCount: 0, plan: 'premium' };
      createComponent({ subscription });

      expect(findUsersInSubscriptionDesc().exists()).toBe(false);
    });

    describe('when subscription is ultimate', () => {
      it('renders text in the card "Users in Subscription"', () => {
        const subscription = { ...license.ULTIMATE };
        createComponent({ subscription });

        expect(findUsersInSubscriptionDesc().exists()).toBe(true);
      });
    });
  });
});
