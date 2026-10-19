import test from 'node:test';
import assert from 'node:assert/strict';
import { hashText, queryResponseText } from '../supabase/functions/_shared/vnpay.mjs';
import { rest } from '../supabase/functions/_shared/http.ts';
const env=new Map(Object.entries({SUPABASE_URL:'https://db.invalid',SUPABASE_ANON_KEY:'anon',SUPABASE_SERVICE_ROLE_KEY:'service',VNPAY_TMN_CODE:'TESTCODE',VNPAY_HASH_SECRET:'secret',VNPAY_SERVER_IP:'127.0.0.1',COMMERCE_JOB_KEY:'job-secret',GEMINI_API_KEY:'ai-secret',GEMINI_MODEL:'configured-model'}));
const handlers=[];globalThis.Deno={env:{get:k=>env.get(k)},serve:h=>handlers.push(h)};
await import('../supabase/functions/vnpay-refund/index.ts');
await import('../supabase/functions/ai-tutor/index.ts');
await import('../supabase/functions/commerce-reconcile/index.ts');
await import('../supabase/functions/vnpay-query/index.ts');
const [refund,ai,job,query]=handlers;
test('successful void database RPC responses do not become false network failures',async()=>{
  for(const response of [new Response(null,{status:204}),new Response('',{status:200})]){
    globalThis.fetch=async()=>response;
    assert.equal(await rest('rpc/finish_ai','service',{},true),null);
  }
});
const id='11111111-1111-4111-8111-111111111111',ref=id.replaceAll('-','');
const json=(v,status=200)=>new Response(JSON.stringify(v),{status});
const request=data=>new Request('https://handler.invalid',{method:'POST',headers:{Authorization:'Bearer user','Content-Type':'application/json'},body:JSON.stringify(data)});
const order={id,parent_id:id,status:'paid',amount_vnd:99000,created_at:'2026-10-16T01:00:00Z'};
const claim={id,created_at:order.created_at,order,payment:{external_transaction_id:'123456'}};
const result={vnp_ResponseId:'response',vnp_Command:'refund',vnp_ResponseCode:'00',vnp_Message:'Success',vnp_TmnCode:'TESTCODE',vnp_TxnRef:ref,vnp_Amount:'9900000',vnp_BankCode:'TEST',vnp_PayDate:'20261016080000',vnp_TransactionNo:'654321',vnp_TransactionType:'02',vnp_TransactionStatus:'00',vnp_OrderInfo:'Refund'};
const refundText=p=>['vnp_ResponseId','vnp_Command','vnp_ResponseCode','vnp_Message','vnp_TmnCode','vnp_TxnRef','vnp_Amount','vnp_BankCode','vnp_PayDate','vnp_TransactionNo','vnp_TransactionType','vnp_TransactionStatus','vnp_OrderInfo'].map(k=>p[k]??'').join('|');
function refundFetch(provider,calls){return async(url,options)=>{
  if(url.includes('/auth/'))return json({id});if(url.endsWith('/is_admin'))return json(true);
  if(url.endsWith('/request_refund'))return json(id);if(url.endsWith('/claim_refund'))return json(claim);
  if(url.endsWith('/finish_refund')){calls.push(JSON.parse(options.body));return json(null);}
  return provider(url,options);
};}
test('refund refuses a parent account before provider access',async()=>{
  globalThis.fetch=async url=>url.includes('/auth/')?json({id}):json(false);
  assert.equal((await refund(request({orderId:id,reason:'Test refund'}))).status,403);
});
test('signed matching full refund settles exactly through the service RPC',async()=>{
  const calls=[];globalThis.fetch=refundFetch(async(url,opt)=>{
    const p=JSON.parse(opt.body);assert.equal(p.vnp_Amount,'9900000');assert.equal(p.vnp_TransactionType,'02');
    const fields=['vnp_RequestId','vnp_Version','vnp_Command','vnp_TmnCode','vnp_TransactionType','vnp_TxnRef','vnp_Amount','vnp_TransactionNo','vnp_TransactionDate','vnp_CreateBy','vnp_CreateDate','vnp_IpAddr','vnp_OrderInfo'];assert.equal(p.vnp_SecureHash,hashText(fields.map(k=>p[k]).join('|'),'secret'));
    return json({...result,vnp_SecureHash:hashText(refundText(result),'secret')});
  },calls);
  assert.equal((await refund(request({orderId:id,reason:'Approved refund'}))).status,200);assert.equal(calls.length,1);assert.equal(calls[0].p_status,'succeeded');
});
test('refund network uncertainty and forged responses never revoke rights as success',async()=>{
  for(const provider of [async()=>{throw Error('timeout');},async()=>json({...result,vnp_SecureHash:'forged'})]){
    const calls=[];globalThis.fetch=refundFetch(provider,calls);assert.equal((await refund(request({orderId:id,reason:'Approved refund'}))).status,503);assert.equal(calls[0].p_status,'unknown');
  }
});
test('claim already sent prevents a duplicate financial request',async()=>{
  globalThis.fetch=async url=>url.includes('/auth/')?json({id}):url.endsWith('/is_admin')?json(true):url.endsWith('/request_refund')?json(id):url.endsWith('/claim_refund')?json(null):assert.fail('must not call provider');
  assert.equal((await refund(request({orderId:id,reason:'Approved refund'}))).status,202);
});
test('AI validates image magic bytes before quota or provider access',async()=>{
  globalThis.fetch=async url=>{assert.ok(url.includes('/auth/'));return json({id});};
  assert.equal((await ai(request({kidId:id,requestId:id,phase:'ocr',mime:'image/jpeg',image:'aGVsbG8='}))).status,400);
});
test('AI quota rejection does not call Gemini',async()=>{
  globalThis.fetch=async url=>url.includes('/auth/')?json({id}):url.endsWith('/claim_ai')?json({},400):assert.fail('must not call provider');
  assert.equal((await ai(request({kidId:id,requestId:id,phase:'hint',problem:'3 cộng 2 bằng bao nhiêu?'}))).status,429);
});
test('AI completed request returns cached result without another charge or inference',async()=>{
  globalThis.fetch=async url=>url.includes('/auth/')?json({id}):url.endsWith('/claim_ai')?json({status:'completed',response:{supported:true,hints:['Đếm thêm hai.'],notice:''}}):assert.fail('must not call provider');
  assert.equal((await (await ai(request({kidId:id,requestId:id,phase:'hint',problem:'3 cộng 2 bằng bao nhiêu?'}))).json()).hints[0],'Đếm thêm hai.');
});
test('AI stores only validated structured output, never the photo or problem input',async()=>{
  let saved;globalThis.fetch=async(url,opt)=>{
    if(url.includes('/auth/'))return json({id});if(url.endsWith('/claim_ai'))return json({status:'claimed'});
    if(url.endsWith('/finish_ai')){saved=JSON.parse(opt.body);return json(null);}
    assert.ok(url.startsWith('https://generativelanguage.googleapis.com/'));assert.equal(opt.headers['x-goog-api-key'],'ai-secret');
    return json({candidates:[{content:{parts:[{text:JSON.stringify({supported:true,hints:['Em biết gì?','Em cần tìm gì?','Thử kiểm tra phép tính nhé.'],notice:''})}]}}]});
  };
  assert.equal((await ai(request({kidId:id,requestId:id,phase:'hint',problem:'3 cộng 2 bằng bao nhiêu?'}))).status,200);assert.equal(saved.p_status,'completed');assert.equal(saved.problem,undefined);assert.equal(saved.image,undefined);
});
test('maintenance job refuses an absent or wrong job key',async()=>{
  globalThis.fetch=()=>assert.fail('must not access database');
  assert.equal((await job(request({}))).status,401);
});
test('maintenance job without configured key fails closed before database access',async()=>{
  const configured=env.get('COMMERCE_JOB_KEY');
  globalThis.fetch=()=>assert.fail('must not access database or provider');
  try {
    for(const value of [undefined,'']) {
      if(value===undefined)env.delete('COMMERCE_JOB_KEY');else env.set('COMMERCE_JOB_KEY',value);
      for(const headers of [{},{'x-job-key':'invalid-qa-key'}]) {
        assert.equal((await job(new Request('https://handler.invalid',{method:'POST',headers,body:'{}'}))).status,401);
      }
    }
  } finally { env.set('COMMERCE_JOB_KEY',configured); }
});
test('signed refund query resolves uncertainty without issuing a second refund',async()=>{
  let settled=false;globalThis.fetch=async(url,opt)=>{
    if(url.includes('/auth/'))return json({id});if(url.includes('/learning_orders?'))return json([order]);if(url.includes('/refund_requests?'))return json([{id}]);
    if(url.endsWith('/claim_vnpay_check'))return json(true);if(url.endsWith('/finish_refund')){assert.equal(JSON.parse(opt.body).p_status,'succeeded');settled=true;return json(null);}
    const p={...result,vnp_Command:'querydr'};return json({...p,vnp_SecureHash:hashText(queryResponseText(p),'secret')});
  };
  assert.equal((await query(request({orderId:id}))).status,200);assert.equal(settled,true);
});
