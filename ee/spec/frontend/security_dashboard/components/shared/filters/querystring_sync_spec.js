import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';

Vue.use(VueRouter);
const router = new VueRouter();

describe('Querystring Sync component', () => {
  let wrapper;

  const createWrapper = ({ validValues } = {}) => {
    wrapper = shallowMount(QuerystringSync, {
      router,
      propsData: { querystringKey: 'values', value: [], validValues },
    });
  };

  afterEach(() => {
    // Clear out the querystring if one exists, it persists between tests.
    if (router.currentRoute.query.values) {
      router.replace({ query: undefined });
    }
  });

  describe('restoring from querystring', () => {
    it.each`
      values              | expected
      ${undefined}        | ${[]}
      ${'undefined'}      | ${['undefined']}
      ${''}               | ${[]}
      ${'abc,def'}        | ${['abc', 'def']}
      ${['abc', 'def']}   | ${['abc', 'def']}
      ${' abc, '}         | ${['abc']}
      ${'3, 2 , 1,3,2,1'} | ${['1', '2', '3']}
    `(
      'emits the input event with $expected when the querystring value is $values',
      ({ values, expected }) => {
        router.replace({ query: { values } });
        createWrapper();

        expect(wrapper.emitted('input')[0][0]).toEqual(expected);
      },
    );

    it('emits the querystring IDs when the browser is navigating', () => {
      router.push({ query: { values: ['abc', 'def'] } });
      createWrapper();
      // JSDom doesn't support window.history.back() and won't change the location nor fire the
      // popstate event, so we need to fake it by doing it manually.
      router.replace({ query: { values: ['abc'] } });
      window.dispatchEvent(new Event('popstate'));

      expect(wrapper.emitted('input')[1][0]).toEqual(['abc']);
    });
  });

  describe('saving to querystring', () => {
    beforeEach(() => {
      createWrapper();
    });

    it.each`
      value                                 | expected
      ${[]}                                 | ${undefined}
      ${[undefined, null, '', ' ']}         | ${undefined}
      ${['undefined']}                      | ${'undefined'}
      ${['abc', undefined, ' ']}            | ${'abc'}
      ${['abc', 'def']}                     | ${'abc,def'}
      ${['1 ', ' 2 ', ' 3', '3', '2', '1']} | ${'1,2,3'}
    `('updates the querystring for value $value', async ({ value, expected }) => {
      wrapper.setProps({ value });
      await nextTick();

      expect(router.currentRoute.query.values).toBe(expected);
    });

    it.each`
      value          | description
      ${[]}          | ${'empty array'}
      ${[undefined]} | ${'undefined'}
      ${[null]}      | ${'null'}
      ${['']}        | ${'empty string'}
      ${[' ']}       | ${'string with only whitespace'}
    `('removes the querystring key when the value is $description', ({ value }) => {
      wrapper.setProps({ value });

      expect(router.currentRoute.query).not.toHaveProperty('values');
    });

    it('does not update if the changed value is the same as the existing querystring', async () => {
      router.replace({ query: { values: 'abc' } });
      const spy = jest.spyOn(router, 'push');
      wrapper.setProps({ value: ['abc'] });
      await nextTick();

      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('cleaning up querystring', () => {
    it.each`
      description                 | query            | expected
      ${'removes invalid values'} | ${'1,2,invalid'} | ${'1,2'}
      ${'sorts alphabetically'}   | ${'2,1'}         | ${'1,2'}
      ${'removes whitespace'}     | ${' 1,2 , 3 '}   | ${'1,2,3'}
      ${'removes duplicates'}     | ${'1,1,2,2,3,3'} | ${'1,2,3'}
      ${'removes empty entries'}  | ${',,,1,2,3'}    | ${'1,2,3'}
      ${'handles no valid IDs'}   | ${',,,5,6,7'}    | ${undefined}
      ${'handles empty string'}   | ${''}            | ${undefined}
    `('cleans up querystring - $description', ({ query, expected }) => {
      router.replace({ query: { values: query } });
      createWrapper({ validValues: ['1', '2', '3'] });

      expect(router.currentRoute.query.values).toEqual(expected);
    });

    it.each`
      description       | query
      ${'no valid IDs'} | ${',,,5,6,7'}
      ${'empty string'} | ${''}
    `('removes the querystring key - $description', ({ query }) => {
      router.replace({ query: { values: query } });
      createWrapper({ validValues: ['1', '2', '3'] });

      expect(router.currentRoute.query).not.toHaveProperty('values');
    });
  });

  describe('popstate listener', () => {
    it('adds a popstate listener on created', () => {
      const spy = jest.spyOn(window, 'addEventListener');
      createWrapper();

      expect(spy).toHaveBeenCalledWith('popstate', wrapper.vm.emitQuerystringIds);
    });

    it('removes the popstate listener on destroyed', () => {
      const spy = jest.spyOn(window, 'removeEventListener');
      createWrapper();
      wrapper.destroy();

      expect(spy).toHaveBeenCalledWith('popstate', wrapper.vm.emitQuerystringIds);
    });
  });
});
