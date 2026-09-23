// Serves dist/ with the cross-origin isolation headers Popcorn needs, then runs
// the page in headless Chromium at 1x CPU and at 4x throttle (a rough phone stand-in).
import { createServer } from "node:http";
import { readFile, readdir, stat, writeFile } from "node:fs/promises";
import { extname, join, resolve } from "node:path";
import { chromium } from "playwright";

const dist = resolve(process.argv[2]);
const outFile = resolve(process.argv[3]);
const types = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript", ".wasm": "application/wasm", ".tar": "application/x-tar", ".json": "application/json" };

const server = createServer(async (req, res) => {
  let path = join(dist, decodeURIComponent(new URL(req.url, "http://x").pathname));
  if (path.endsWith("/")) path += "index.html";
  const headers = { "Cross-Origin-Opener-Policy": "same-origin", "Cross-Origin-Embedder-Policy": "require-corp" };
  try {
    let body = await readFile(path);
    if (path.endsWith(".tar")) {
      try { body = await readFile(path + ".gz"); headers["Content-Encoding"] = "gzip"; } catch {}
    }
    res.writeHead(200, { ...headers, "Content-Type": types[extname(path)] || "application/octet-stream" });
    res.end(body);
  } catch {
    res.writeHead(404, headers); res.end();
  }
}).listen(4000);

async function sizes(dir, prefix = "") {
  const out = {};
  for (const name of await readdir(dir)) {
    const p = join(dir, name), s = await stat(p);
    if (s.isDirectory()) Object.assign(out, await sizes(p, prefix + name + "/"));
    else out[prefix + name] = s.size;
  }
  return out;
}

const browser = await chromium.launch();
const results = { files: await sizes(dist), runs: {} };
for (const rate of [1, 4]) {
  const page = await browser.newPage();
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Emulation.setCPUThrottlingRate", { rate });
  page.on("console", (m) => console.log(`[${rate}x] ${m.text()}`));
  await page.goto("http://localhost:4000/");
  results.runs[`cpu_${rate}x`] = await page.evaluate(() => window.__results);
  await page.close();
}
await browser.close();
server.close();
await writeFile(outFile, JSON.stringify(results, null, 2) + "\n");
console.log(JSON.stringify(results, null, 2));
if (Object.values(results.runs).some((r) => r.error)) process.exit(1);
