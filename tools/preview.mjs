import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
const root = resolve('build/web');
const types = {'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.woff2':'font/woff2','.ttf':'font/ttf'};
http.createServer(async (req,res) => {
  try {
    const path = resolve(root, '.' + decodeURIComponent(new URL(req.url,'http://localhost').pathname));
    if(path !== root && !path.startsWith(root + sep)) {res.writeHead(403);res.end();return;}
    const file = path === root ? resolve(root,'index.html') : path;
    const data = await readFile(file);
    res.writeHead(200, {'Content-Type':types[extname(file)] || 'application/octet-stream'});res.end(data);
  } catch {res.writeHead(404);res.end('Not found');}
}).listen(8791,'127.0.0.1',()=>console.log('Preview: http://127.0.0.1:8791'));
