import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionDetailsUserInfo, {
  billableUsersURL,
  trueUpURL,
} from 'ee/admin/subscriptions/show/components/subscription_details_user_info.vue';
import {
  billableUsersText,
  billableUsersTitle,
  maximumUsersText,
  maximumUsersTitle,
  usersInSubscriptionText,
  usersInSubscriptionTitle,
  usersOverSubscriptionText,
  usersOverSubscriptionTitle,
} from 'ee/admin/subscriptions/show/constants';
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
          subscription: license.ULTIMATE,
          ...props,
        },
        stubs: {
          GlCard,
          GlSprintf: stubGlSprintf ? GlSprintf : true,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    testId                     | info    | title                         | text                         | link
    ${'users-in-subscription'} | ${'10'} | ${usersInSubscriptionTitle}   | ${usersInSubscriptionText}   | ${false}
    ${'billable-users'}        | ${'8'}  | ${billableUsersTitle}         | ${billableUsersText}         | ${billableUsersURL}
    ${'maximum-users'}         | ${'8'}  | ${maximumUsersTitle}          | ${maximumUsersText}          | ${false}
    ${'users-over-license'}    | ${'0'}  | ${usersOverSubscriptionTitle} | ${usersOverSubscriptionText} | ${trueUpURL}
  `('with data for $card', ({ testId, info, title, text, link }) => {
    beforeEach(() => {
      createComponent();
    });

    const findUseCard = () => wrapper.findByTestId(testId);

    it(`displays the info`, () => {
      expect(findUseCard().find('h2').text()).toBe(info);
    });

    it(`displays the title`, () => {
      expect(findUseCard().find('h5').text()).toBe(title);
    });

    itif(link)(`displays the content with a link`, () => {
      expect(findUseCard().findComponent(GlSprintf).attributes('message')).toBe(text);
    });

    itif(!link)('displays a simple content', () => {
      expect(findUseCard().find('p').text()).toBe(text);
    });

    itif(link)(`has a link`, () => {
      createComponent({}, true);
      expect(findUseCard().findComponent(GlLink).attributes('href')).toBe(link);
    });

    itif(!link)(`has not a link`, () => {
      createComponent({}, true);
      expect(findUseCard().findComponent(GlLink).exists()).toBe(link);
    });
  });

  describe('Users is subscription', () => {
    it('should display the value when present', () => {
      const subscription = { ...license.ULTIMATE, usersInLicenseCount: 0 };
      createComponent({ subscription });

      expect(findSubscriptionText()).toBe('0');
    });

    it('should display Unlimited when users in license is null', () => {
      const subscription = { ...license.ULTIMATE, usersInLicenseCount: null };
      createComponent({ subscription });

      expect(findSubscriptionText()).toBe('Unlimited');
    });
  });
});
