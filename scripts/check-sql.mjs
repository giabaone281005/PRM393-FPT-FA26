import { readFileSync, readdirSync } from 'node:fs';

// Structural validation only. Does not parse PL/pgSQL or connect to any database.
export function checkSql(source,label='SQL') {
  let depth=0;
  for(let i=0;i<source.length;i++){
    const c=source[i],next=source[i+1];
    if(c==='-'&&next==='-'){const end=source.indexOf('\n',i+2);i=end<0?source.length:end;continue;}
    if(c==='/'&&next==='*'){const end=source.indexOf('*/',i+2);if(end<0)throw Error(`${label}: unclosed comment`);i=end+1;continue;}
    if(c==="'"||c==='"'){
      let closed=false;
      for(i++;i<source.length;i++){if(source[i]===c){if(source[i+1]===c){i++;continue;}closed=true;break;}}
      if(!closed)throw Error(`${label}: unclosed quote`);continue;
    }
    if(c==='$'){
      const tag=source.slice(i).match(/^\$(?:[a-zA-Z_][a-zA-Z_0-9]*)?\$/)?.[0];
      if(!tag)throw Error(`${label}: invalid dollar delimiter at ${i}`);
      const end=source.indexOf(tag,i+tag.length);if(end<0)throw Error(`${label}: unclosed ${tag}`);
      checkSql(source.slice(i+tag.length,end),`${label} dollar body`);i=end+tag.length-1;continue;
    }
    if(c==='(')depth++;if(c===')'&&--depth<0)throw Error(`${label}: extra closing parenthesis at ${i}`);
  }
  if(depth!==0)throw Error(`${label}: ${depth} unclosed parentheses`);
}
const files=[...readdirSync('supabase/migrations').filter(f=>/^202610(18|19|20|21)/.test(f)).map(f=>'supabase/migrations/'+f),...readdirSync('supabase/tests').filter(f=>f.endsWith('.sql')).map(f=>'supabase/tests/'+f),...readdirSync('supabase/operations').filter(f=>f.endsWith('.sql')).map(f=>'supabase/operations/'+f)];
for(const file of files)checkSql(readFileSync(file,'utf8'),file);
const signatures=new Set();
const schemaSource=readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).map(f=>readFileSync('supabase/migrations/'+f,'utf8')).join('\n');
const normalize=t=>t.trim().toLowerCase().replace(/^int$/,'integer').replace(/^bool$/,'boolean');
const key=(name,types)=>`${name.toLowerCase()}(${types.map(normalize).join(',')})`;
for(const match of schemaSource.matchAll(/CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+((?:public|private)\.\w+)\s*\(([^)]*)\)/gi)){
  const args=match[2].trim()?match[2].split(',').map(arg=>arg.trim().split(/\s+/)[1]):[];
  signatures.add(key(match[1],args));
}
for(const file of files.filter(f=>f.includes('/migrations/'))){
  const source=readFileSync(file,'utf8');
  for(const statement of source.matchAll(/(?:GRANT|REVOKE)\s+[^;]*?ON\s+FUNCTION\s+([^;]+?)\s+(?:TO|FROM)\s+[^;]+;/gi)){
    for(const fn of statement[1].matchAll(/((?:public|private)\.\w+)\s*\(([^)]*)\)/gi)){
      const types=fn[2].trim()?fn[2].split(','):[];
      if(!signatures.has(key(fn[1],types)))throw Error(`${file}: grant/revoke refers to unknown function ${key(fn[1],types)}`);
    }
  }
  for(const wrapper of source.matchAll(/CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+public\.(\w+)\s*\(([^)]*)\)[^$]+\$\$\s*SELECT\s+(private\.\w+)\(([^)]*)\);\s*\$\$/gi)){
    const params=wrapper[2].trim()?wrapper[2].split(',').map(arg=>arg.trim().split(/\s+/)[0]):[];
    const passed=wrapper[4].trim()?wrapper[4].split(',').map(arg=>arg.trim()):[];
    for(const arg of passed)if(!params.includes(arg))throw Error(`${file}: wrapper ${wrapper[1]} passes undeclared ${arg}`);
  }
}
console.log(`Structural checks passed: ${files.length} SQL files. Database execution is still required on staging.`);
