{{flutter_js}}
{{flutter_build_config}}

function removeLoaderSafely() {
  const loader = document.getElementById('app-loader');
  if (!loader) return;
  if (typeof loader.remove === 'function') {
    loader.remove();
    return;
  }
  if (loader.parentNode) {
    loader.parentNode.removeChild(loader);
  }
}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    removeLoaderSafely();
    removeLoaderSafely();
  }
});
