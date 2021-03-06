// Renders diagrams and flowcharts from text using Mermaid in any element with the
// `js-render-mermaid` class.
//
// Example markup:
//
// <pre class="js-render-mermaid">
//  graph TD;
//    A-- > B;
//    A-- > C;
//    B-- > D;
//    C-- > D;
// </pre>
//

import Flash from './flash';

export default function renderMermaid($els) {
  if (!$els.length) return;

  import(/* webpackChunkName: 'mermaid' */ 'blackst0ne-mermaid').then((mermaid) => {
    mermaid.initialize({
      loadOnStart: false,
      theme: 'neutral',
    });

    $els.each((i, el) => {
      const source = el.textContent;

      mermaid.init(undefined, el, (id) => {
        const svg = document.getElementById(id);

        svg.classList.add('mermaid');

        // pre > code > svg
        svg.closest('pre').replaceWith(svg);

        // We need to add the original source into the DOM to allow Copy-as-GFM
        // to access it.
        const sourceEl = document.createElement('text');
        sourceEl.classList.add('source');
        sourceEl.setAttribute('display', 'none');
        sourceEl.textContent = source;

        svg.appendChild(sourceEl);
      });
    });
  }).catch((err) => {
    Flash(`Can't load mermaid module: ${err}`);
  });
}
