// Runs inside the Hermes CLI. Reports the globals Popcorn needs.
var out = {};
function has(name) {
  try { return typeof globalThis[name] !== 'undefined'; } catch (e) { return false; }
}
['WebAssembly', 'SharedArrayBuffer', 'Atomics', 'Worker', 'TextDecoder', 'TextEncoder', 'queueMicrotask']
  .forEach(function (n) { out[n] = has(n); });
try { out.eval = eval('1 + 1') === 2; } catch (e) { out.eval = 'throws: ' + e; }
try { out.new_Function = new Function('return 3')() === 3; } catch (e) { out.new_Function = 'throws: ' + e; }
// Smallest valid wasm module: (module (func (export "f") (result i32) i32.const 42))
var bytes = [0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,7,5,1,1,102,0,0,10,6,1,4,0,65,42,11];
try {
  var m = new WebAssembly.Module(new Uint8Array(bytes));
  out.wasm_instantiate = new WebAssembly.Instance(m, {}).exports.f() === 42;
} catch (e) { out.wasm_instantiate = 'fails: ' + e; }
try { out.HermesInternal_version = HermesInternal.getRuntimeProperties()['OSS Release Version']; } catch (e) {}
print(JSON.stringify(out, null, 2));
