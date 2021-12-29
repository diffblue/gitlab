import { shallowMount } from '@vue/test-utils';
import UrlSyncMixin from 'ee/analytics/shared/mixins/url_sync_mixin';

const defaultData = {
  group_id: null,
  project_ids: [],
};

const createComponent = () => {
  return shallowMount(
    {
      mixins: [UrlSyncMixin],
      render(h) {
        return h('div');
      },
    },
    {
      computed: {
        query() {
          return {
            group_id: this.group_id,
            project_ids: this.project_ids,
          };
        },
      },
      data() {
        return { ...defaultData };
      },
    },
  );
};

describe('UrlSyncMixin', () => {
  let wrapper;
  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.vm.$destroy();
  });

  describe('query', () => {
    it('has the default state', () => {
      expect(wrapper.vm.query).toEqual(defaultData);
    });

    describe('with parameter changes', () => {
      it.each`
        param            | payload         | updatedParams
        ${'group_id'}    | ${'test-group'} | ${{ group_id: 'test-group' }}
        ${'project_ids'} | ${[1, 2]}       | ${{ project_ids: [1, 2] }}
      `('is updated when the $param parameter changes', ({ param, payload, updatedParams }) => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({ [param]: payload });

        expect(wrapper.vm.query).toEqual({
          ...defaultData,
          ...updatedParams,
        });
      });
    });
  });
});
