import { isScrolledToBottom } from '~/lib/utils/scroll_utils';

describe('isScrolledToBottom', () => {
  const setDocumentElementProperties = ({ scrollTop, clientHeight, scrollHeight }) => {
    Object.defineProperties(Element.prototype, {
      scrollTop: {
        get() {
          return scrollTop;
        },
      },
      clientHeight: {
        get() {
          return clientHeight;
        },
      },
      scrollHeight: {
        get() {
          return scrollHeight;
        },
      },
    });
  };

  afterEach(() => {
    // Approximately reset to jsdom's default behaviour.
    setDocumentElementProperties({ scrollTop: 0, clientHeight: 0, scrollHeight: 0 });
  });

  it.each`
    context                                                           | scrollTop | scrollHeight | result
    ${'returns false when not scrolled to bottom'}                    | ${0}      | ${2000}      | ${false}
    ${'returns true when scrolled to bottom'}                         | ${1000}   | ${2000}      | ${true}
    ${'returns true when scrolled to bottom with subpixel precision'} | ${999.25} | ${2000}      | ${true}
    ${'returns true when cannot scroll'}                              | ${0}      | ${500}       | ${true}
  `('$context', ({ scrollTop, scrollHeight, result }) => {
    setDocumentElementProperties({ scrollTop, clientHeight: 1000, scrollHeight });

    expect(isScrolledToBottom()).toBe(result);
  });
});
