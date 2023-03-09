import { GlBanner, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import SharedSurveyBanner from 'ee/vue_shared/survey_banner/survey_banner.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import toast from '~/vue_shared/plugins/global_toast';

const TEST_LOCAL_STORAGE_KEY = 'testLocalStorageKey';
const TEST_BANNER_ID = 'testBannerId';

jest.mock('~/vue_shared/plugins/global_toast');

describe('Shared Survey Banner component', () => {
  let wrapper;
  const findGlBanner = () => wrapper.findComponent(GlBanner);
  const findAskLaterButton = () => wrapper.findByTestId('ask-later-button');
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const getOffsetDateString = (days) => {
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date.toISOString();
  };

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SharedSurveyBanner, {
        propsData: {
          surveyLink: 'foo.bar',
          daysToAskLater: 7,
          title: 'testTitle',
          buttonText: 'buttonText',
          description: 'description',
          toastMessage: 'toastMessage',
          storageKey: TEST_LOCAL_STORAGE_KEY,
          bannerId: TEST_BANNER_ID,
          svgPath: '/foo.svg',
          ...props,
        },
        stubs: { GlBanner, GlButton, LocalStorageSync },
      }),
    );
  };

  beforeEach(() => {
    gon.features = {};
  });

  afterEach(() => {
    localStorage.removeItem(TEST_LOCAL_STORAGE_KEY);
  });

  beforeEach(() => {
    createWrapper();
  });

  it('shows the banner with the correct components and props', () => {
    const { title, buttonText, description, svgPath } = wrapper.props();

    expect(findGlBanner().html()).toContain(description);
    expect(findAskLaterButton().exists()).toBe(true);
    expect(findLocalStorageSync().props('asString')).toBe(true);
    expect(findGlBanner().props()).toMatchObject({
      title,
      buttonText,
      svgPath,
    });
  });

  it.each`
    showOrHide | phrase                     | localStorageValue          | isShown
    ${'hides'} | ${'a future date'}         | ${getOffsetDateString(1)}  | ${false}
    ${'shows'} | ${'a past date'}           | ${getOffsetDateString(-1)} | ${true}
    ${'hides'} | ${'the current survey ID'} | ${TEST_BANNER_ID}          | ${false}
    ${'shows'} | ${'a different survey ID'} | ${'SOME OTHER ID'}         | ${true}
  `(
    '$showOrHide the banner if the localStorage value is $phrase',
    async ({ localStorageValue, isShown }) => {
      localStorage.setItem(TEST_LOCAL_STORAGE_KEY, localStorageValue);
      createWrapper();
      await nextTick();

      expect(findGlBanner().exists()).toBe(isShown);
    },
  );

  describe('closing the banner', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('hides the banner and will set it to reshow later if the "Ask again later" button is clicked', async () => {
      expect(findGlBanner().exists()).toBe(true);

      findAskLaterButton().vm.$emit('click');
      await nextTick();
      const date = new Date(localStorage.getItem(TEST_LOCAL_STORAGE_KEY));

      expect(findGlBanner().exists()).toBe(false);
      expect(toast).toHaveBeenCalledTimes(1);
      expect(date > new Date()).toBe(true);
    });

    it('hides the banner and sets it to never show again if the close button is clicked', async () => {
      expect(findGlBanner().exists()).toBe(true);

      findGlBanner().vm.$emit('close');
      await nextTick();

      expect(findGlBanner().exists()).toBe(false);
      expect(localStorage.getItem(TEST_LOCAL_STORAGE_KEY)).toBe(TEST_BANNER_ID);
    });
  });
});
