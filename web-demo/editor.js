// editor.js — CodeMirror + Pyodide runner glue (web demo)
(async function(){
  const statusEl = document.getElementById('status');
  const outputEl = document.getElementById('output');
  const runBtn = document.getElementById('runBtn');
  const loadSample = document.getElementById('loadSample');
  const clearOutput = document.getElementById('clearOutput');

  function setStatus(s){ statusEl.textContent = s; }
  function appendOutput(s){ outputEl.textContent += s + '\n'; outputEl.scrollTop = outputEl.scrollHeight; }
  function clear(){ outputEl.textContent = ''; }

  // Initialize CodeMirror
  const textarea = document.getElementById('editor');
  const editor = CodeMirror.fromTextArea(textarea, {mode:'python',lineNumbers:true,tabSize:4,indentUnit:4,matchBrackets:true});

  // Load Pyodide
  setStatus('Loading Pyodide... (this may take a few seconds)');
  let pyodide = null;
  try{
    pyodide = await loadPyodide({indexURL:'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/'});
    setStatus('Pyodide ready');
  }catch(e){
    setStatus('Pyodide failed to load: '+e);
    console.error(e);
    return;
  }

  // Run code and capture stdout/stderr
  async function runCode(code){
    appendOutput('> Running...');
    try{
      // Best-effort package loading
      try{ await pyodide.loadPackagesFromImports(code); }catch(e){ appendOutput('[pkg load error] '+e); }

      pyodide.globals.set('user_code', code);
      const runner = `\nimport sys, io, traceback\nold_out = sys.stdout\nold_err = sys.stderr\nsys.stdout = io.StringIO()\nsys.stderr = io.StringIO()\ntry:\n    exec(user_code, {})\nexcept Exception:\n    traceback.print_exc()\nout = sys.stdout.getvalue()\nerr = sys.stderr.getvalue()\nsys.stdout = old_out\nsys.stderr = old_err\n(out, err)\n`;

      const res = await pyodide.runPythonAsync(runner);
      const out = res[0] ? res[0].toString() : '';
      const err = res[1] ? res[1].toString() : '';
      if(out) appendOutput(out.trim());
      if(err) appendOutput('--- stderr ---\n'+err.trim());
      appendOutput('> Finished');
    }catch(ex){
      appendOutput('Run error: '+ex);
    }
  }

  runBtn.addEventListener('click', async ()=>{
    clearOutputIfFirst();
    const code = editor.getValue();
    await runCode(code);
  });

  loadSample.addEventListener('click', ()=>{
    const sample = `# Sample Tuzday web demo\nfor i in range(3):\n    print('Line', i)\n`;
    editor.setValue(sample);
  });

  clearOutput.addEventListener('click', ()=>{ clear(); setStatus('Pyodide ready'); });

  function clearOutputIfFirst(){ if(outputEl.textContent.trim().length===0) return; }

  setStatus('Ready');
})();
