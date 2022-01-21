import { GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GeoNodeProgressBar from 'ee/geo_nodes/components/details/geo_node_progress_bar.vue';
import GeoNodeReplicationDetailsResponsive from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_details_responsive.vue';
import { HELP_INFO_URL } from 'ee/geo_nodes/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('GeoNodeReplicationDetailsResponsive', () => {
  let wrapper;

  const defaultProps = {
    replicationItems: [],
  };

  const createComponent = (props, slots) => {
    wrapper = extendedWrapper(
      shallowMount(GeoNodeReplicationDetailsResponsive, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        scopedSlots: {
          ...slots,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findGlPopoverLink = () => findGlPopover().findComponent(GlLink);
  const findReplicationDetailsHeader = () => wrapper.findByTestId('replication-details-header');
  const findReplicationDetailsItems = () => wrapper.findAllByTestId('replication-details-item');
  const findFirstReplicationDetailsItemSyncStatus = () =>
    extendedWrapper(findReplicationDetailsItems().at(0)).findByTestId('sync-status');
  const findFirstReplicationDetailsItemVerifStatus = () =>
    extendedWrapper(findReplicationDetailsItems().at(0)).findByTestId('verification-status');

  describe('template', () => {
    describe('with default slots', () => {
      describe('always', () => {
        beforeEach(() => {
          createComponent();
        });

        it('renders the replication details header', () => {
          expect(findReplicationDetailsHeader().exists()).toBe(true);
        });

        it('renders the replication details header items correctly', () => {
          expect(findReplicationDetailsHeader().text()).toContain(
            'Data type Component Synchronization status Verification status',
          );
        });

        it('renders the question icon correctly', () => {
          expect(findGlIcon().exists()).toBe(true);
          expect(findGlIcon().props('name')).toBe('question');
        });

        it('renders the GlPopover always', () => {
          expect(findGlPopover().exists()).toBe(true);
        });

        it('renders the popover link correctly', () => {
          expect(findGlPopoverLink().exists()).toBe(true);
          expect(findGlPopoverLink().attributes('href')).toBe(HELP_INFO_URL);
        });
      });

      describe('replication details', () => {
        describe('when null', () => {
          beforeEach(() => {
            createComponent({ replicationItems: null });
          });

          it('does not render any replicable items', () => {
            expect(findReplicationDetailsItems()).toHaveLength(0);
          });
        });
      });

      describe.each`
        description                    | replicationItems                                                                                                                                          | renderSyncProgress | renderVerifProgress
        ${'with no data'}              | ${[{ dataTypeTitle: 'Test Title', component: 'Test Component', syncValues: null, verificationValues: null }]}                                             | ${false}           | ${false}
        ${'with no verification data'} | ${[{ dataTypeTitle: 'Test Title', component: 'Test Component', syncValues: { total: 100, success: 0 }, verificationValues: null }]}                       | ${true}            | ${false}
        ${'with no sync data'}         | ${[{ dataTypeTitle: 'Test Title', component: 'Test Component', syncValues: null, verificationValues: { total: 50, success: 50 } }]}                       | ${false}           | ${true}
        ${'with all data'}             | ${[{ dataTypeTitle: 'Test Title', component: 'Test Component', syncValues: { total: 100, success: 0 }, verificationValues: { total: 50, success: 50 } }]} | ${true}            | ${true}
      `('$description', ({ replicationItems, renderSyncProgress, renderVerifProgress }) => {
        beforeEach(() => {
          createComponent({ replicationItems });
        });

        it('renders sync progress correctly', () => {
          expect(
            findFirstReplicationDetailsItemSyncStatus().findComponent(GeoNodeProgressBar).exists(),
          ).toBe(renderSyncProgress);
          expect(
            extendedWrapper(findFirstReplicationDetailsItemSyncStatus()).findByText('N/A').exists(),
          ).toBe(!renderSyncProgress);
        });

        it('renders verification progress correctly', () => {
          expect(
            findFirstReplicationDetailsItemVerifStatus().findComponent(GeoNodeProgressBar).exists(),
          ).toBe(renderVerifProgress);
          expect(
            extendedWrapper(findFirstReplicationDetailsItemVerifStatus())
              .findByText('N/A')
              .exists(),
          ).toBe(!renderVerifProgress);
        });
      });
    });

    describe('with custom title slot', () => {
      beforeEach(() => {
        const title =
          '<template #title="{ translations }"><span>{{ translations.component }} {{ translations.status }}</span></template>';
        createComponent(null, { title });
      });

      it('renders the replication details header', () => {
        expect(findReplicationDetailsHeader().exists()).toBe(true);
      });

      it('renders the replication details header with access to the translations prop', () => {
        expect(findReplicationDetailsHeader().text()).toBe('Component Status');
      });
    });

    describe('with custom default slot', () => {
      beforeEach(() => {
        const defaultSlot =
          '<template #default="{ item, translations }"><span>{{ item.component }} {{ item.dataTypeTitle }} {{ translations.status }}</span></template>';
        createComponent(
          { replicationItems: [{ component: 'Test Component', dataTypeTitle: 'Test Title' }] },
          { default: defaultSlot },
        );
      });

      it('renders the replication details items section', () => {
        expect(findReplicationDetailsItems().exists()).toBe(true);
      });

      it('renders the replication details items section with access to the item and translations prop', () => {
        expect(findReplicationDetailsItems().at(0).text()).toBe('Test Component Test Title Status');
      });
    });
  });
});
