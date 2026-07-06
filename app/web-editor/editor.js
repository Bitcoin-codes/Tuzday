// Minimal editor.js: binds a CodeMirror editor and a simple JSON bridge to NativeBridge
(function () {
  // Create CodeMirror
  const textarea = document.getElementById('editor');
  const editor = CodeMirror.fromTextArea(textarea, {
    mode: 'javascript',
    lineNumbers: true,
    theme: 'default',
    viewportMargin: Infinity,
  });

  const statusEl = document.getElementById('status');
  function setStatus(s) {
    if (statusEl) statusEl.textContent = s;
    console.log('[web-editor] ' + s);
  }

  // Send JSON message to native using the platform-provided bridge
  function sendMessage(msg) {
    try {
      const json = JSON.stringify(msg);
      if (window.NativeBridge && window.NativeBridge.postMessage) {
        window.NativeBridge.postMessage(json);
      } else if (window.ReactNativeWebView && window.ReactNativeWebView.postMessage) {
        // react-native-webview fallback
        window.ReactNativeWebView.postMessage(json);
      } else {
        console.log('No native bridge available; message:', msg);
      }
    } catch (e) {
      console.error('sendMessage error', e);
    }
  }

  // Handler called by native:
  // native calls: window.onNativeMessage({ type, id, payload })
  window.onNativeMessage = function (msg) {
    try {
      const type = msg.type || '';
      const id = msg.id || '';
      const payload = msg.payload || {};
      if (type === 'file.open.response') {
        if (payload.content != null) {
          editor.setValue(payload.content);
          setStatus('Loaded: ' + (payload.path || ''));
        } else {
          setStatus('file.open failed');
        }
      } else if (type === 'file.save.response') {
        if (payload.mtime) {
          setStatus('Saved at ' + payload.mtime);
        } else {
          setStatus('Save response received');
        }
      } else {
        console.log('Unhandled message from native', msg);
      }
    } catch (e) {
      console.error('onNativeMessage error', e);
    }
  };

  // Buttons
  document.getElementById('openBtn').addEventListener('click', function () {
    const id = 'open_' + Date.now();
    sendMessage({
      type: 'file.open',
      id: id,
      payload: { path: 'projects/demo/sample.txt' },
    });
    setStatus('Requested open...');
  });

  document.getElementById('saveBtn').addEventListener('click', function () {
    const id = 'save_' + Date.now();
    const content = editor.getValue();
    sendMessage({
      type: 'file.save',
      id: id,
      payload: {
        path: 'projects/demo/sample.txt',
        content: content,
        encoding: 'utf8',
      },
    });
    setStatus('Requested save...');
  });

  // Small helper: allow native to request the current buffer
  window.requestCurrentBuffer = function () {
    return { content: editor.getValue() };
  };

  setStatus('Editor ready');
})();
