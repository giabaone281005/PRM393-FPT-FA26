(function dartProgram(){function copyProperties(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
b[r]=a[r]}}function mixinPropertiesHard(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
if(!b.hasOwnProperty(r)){b[r]=a[r]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var t=function(){}
t.prototype={p:{}}
var s=new t()
if(!(Object.getPrototypeOf(s)&&Object.getPrototypeOf(s).p===t.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var r=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(r))return true}}catch(q){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var t=Object.create(b.prototype)
copyProperties(a.prototype,t)
a.prototype=t}}function inheritMany(a,b){for(var t=0;t<b.length;t++){inherit(b[t],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){var s=d()
if(a[b]!==t){A.ii(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.b(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.dP(b)
return new t(c,this)}:function(){if(t===null)t=A.dP(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.dP(a).prototype
return t}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var t=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var s=staticTearOffGetter(t)
a[b]=s}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var t=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var s=instanceTearOffGetter(c,t)
a[b]=s}function setOrUpdateInterceptorsByTag(a){var t=v.interceptorsByTag
if(!t){v.interceptorsByTag=a
return}copyProperties(a,t)}function setOrUpdateLeafTags(a){var t=v.leafTags
if(!t){v.leafTags=a
return}copyProperties(a,t)}function updateTypes(a){var t=v.types
var s=t.length
t.push.apply(t,a)
return s}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var t=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},s=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:t(0,0,null,["$0"],0),_instance_1u:t(0,1,null,["$1"],0),_instance_2u:t(0,2,null,["$2"],0),_instance_0i:t(1,0,null,["$0"],0),_instance_1i:t(1,1,null,["$1"],0),_instance_2i:t(1,2,null,["$2"],0),_static_0:s(0,null,["$0"],0),_static_1:s(1,null,["$1"],0),_static_2:s(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
dT(a,b,c,d){return{i:a,p:b,e:c,x:d}},
dQ(a){var t,s,r,q,p,o="_$dart_js",n=a[v.dispatchPropertyName]
if(n==null)if($.dR==null){A.hW()
n=a[v.dispatchPropertyName]}if(n!=null){t=n.p
if(!1===t)return n.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return n.i
if(n.e===s)throw A.d(A.ek("Return interceptor for "+A.t(t(a,n))))}r=a.constructor
if(r==null)q=null
else{p=$.c9
if(p==null)p=$.c9=A.dc(o)
q=r[p]}if(q!=null)return q
q=A.i0(a)
if(q!=null)return q
if(typeof a=="function")return B.I
t=Object.getPrototypeOf(a)
if(t==null)return B.l
if(t===Object.prototype)return B.l
if(typeof r=="function"){p=$.c9
if(p==null)p=$.c9=A.dc(o)
Object.defineProperty(r,p,{value:B.h,enumerable:false,writable:true,configurable:true})
return B.h}return B.h},
bZ(a,b){return A.b(new Array(a),b.i("v<0>"))},
S(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.aE.prototype
return J.bq.prototype}if(typeof a=="string")return J.aq.prototype
if(a==null)return J.aF.prototype
if(typeof a=="boolean")return J.bp.prototype
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a5.prototype
if(typeof a=="symbol")return J.aJ.prototype
if(typeof a=="bigint")return J.aH.prototype
return a}if(a instanceof A.w)return a
return J.dQ(a)},
y(a){if(typeof a=="string")return J.aq.prototype
if(a==null)return a
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a5.prototype
if(typeof a=="symbol")return J.aJ.prototype
if(typeof a=="bigint")return J.aH.prototype
return a}if(a instanceof A.w)return a
return J.dQ(a)},
a0(a){if(a==null)return a
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a5.prototype
if(typeof a=="symbol")return J.aJ.prototype
if(typeof a=="bigint")return J.aH.prototype
return a}if(a instanceof A.w)return a
return J.dQ(a)},
h(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.S(a).v(a,b)},
r(a,b){if(typeof b==="number")if(Array.isArray(a)||A.hZ(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.a0(a).h(a,b)},
dv(a,b){return J.a0(a).R(a,b)},
e2(a,b){return J.a0(a).B(a,b)},
bW(a){return J.S(a).gA(a)},
f7(a){return J.y(a).gq(a)},
f8(a){return J.a0(a).gL(a)},
a1(a){return J.a0(a).gp(a)},
a2(a){return J.y(a).gj(a)},
f9(a){return J.S(a).gt(a)},
e3(a){return J.a0(a).G(a)},
ay(a){return J.S(a).k(a)},
bn:function bn(){},
bp:function bp(){},
aF:function aF(){},
aI:function aI(){},
a6:function a6(){},
bD:function bD(){},
b0:function b0(){},
a5:function a5(){},
aH:function aH(){},
aJ:function aJ(){},
v:function v(a){this.$ti=a},
bo:function bo(){},
c_:function c_(a){this.$ti=a},
ac:function ac(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aG:function aG(){},
aE:function aE(){},
bq:function bq(){},
aq:function aq(){}},A={dz:function dz(){},
fc(a,b,c){if(u.Q.b(a))return new A.b3(a,b.i("@<0>").E(c).i("b3<1,2>"))
return new A.ad(a,b.i("@<0>").E(c).i("ad<1,2>"))},
dS(a){var t,s
for(t=$.O.length,s=0;s<t;++s)if(a===$.O[s])return!0
return!1},
bY(){return new A.bI("No element")},
a8:function a8(){},
az:function az(a,b){this.a=a
this.$ti=b},
ad:function ad(a,b){this.a=a
this.$ti=b},
b3:function b3(a,b){this.a=a
this.$ti=b},
b2:function b2(){},
V:function V(a,b){this.a=a
this.$ti=b},
bt:function bt(a){this.a=a},
e:function e(){},
X:function X(){},
Y:function Y(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aQ:function aQ(a,b,c){this.a=a
this.b=b
this.$ti=c},
a_:function a_(a,b,c){this.a=a
this.b=b
this.$ti=c},
b1:function b1(a,b,c){this.a=a
this.b=b
this.$ti=c},
aC:function aC(a,b,c){this.a=a
this.b=b
this.$ti=c},
aD:function aD(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aB:function aB(a){this.$ti=a},
I:function I(){},
bd:function bd(){},
eQ(a){var t=A.eP(a)
if(t!=null)return t
return"minified:"+a},
hZ(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.D.b(a)},
t(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.ay(a)
return t},
bE(a){var t,s=$.ef
if(s==null)s=$.ef=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
bF(a){var t,s,r,q
if(a instanceof A.w)return A.N(A.T(a),null)
t=J.S(a)
if(t===B.G||t===B.J||u.o.b(a)){s=B.i(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.N(A.T(a),null)},
fu(a){var t,s,r
if(typeof a=="number"||A.dL(a))return J.ay(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.a4)return a.k(0)
t=$.f4()
for(s=0;s<1;++s){r=t[s].aB(a)
if(r!=null)return r}return"Instance of '"+A.bF(a)+"'"},
E(a){var t
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.k.a7(t,10)|55296)>>>0,t&1023|56320)}throw A.d(A.bG(a,0,1114111,null,null))},
dd(a){throw A.d(A.hK(a))},
A(a,b){if(a==null)J.a2(a)
throw A.d(A.cF(a,b))},
cF(a,b){var t,s="index"
if(!A.D(b))return new A.a3(!0,b,s,null)
t=J.a2(a)
if(b<0||b>=t)return A.dx(b,t,a,s)
return new A.aX(null,null,!0,b,s,"Value not in range")},
hK(a){return new A.a3(!0,a,null,null)},
d(a){return A.G(a,new Error())},
G(a,b){var t
if(a==null)a=new A.b_()
b.dartException=a
t=A.ij
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
ij(){return J.ay(this.dartException)},
ds(a,b){throw A.G(a,b==null?new Error():b)},
dX(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.ds(A.h7(a,b,c),t)},
h7(a,b,c){var t,s,r,q,p,o,n,m,l
if(typeof b=="string")t=b
else{s="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
r=s.length
q=b
if(q>r){c=q/r|0
q%=r}t=s[q]}p=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
o=u.j.b(a)?"list":"ByteData"
n=a.$flags|0
m="a "
if((n&4)!==0)l="constant "
else if((n&2)!==0){l="unmodifiable "
m="an "}else l=(n&1)!==0?"fixed-length ":""
return new A.bN("'"+t+"': Cannot "+p+" "+m+l+o)},
dW(a){throw A.d(A.H(a))},
Z(a){var t,s,r,q,p,o
a=A.ih(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.b([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.c7(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
c8(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
ej(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
dA(a,b){var t=b==null,s=t?null:b.method
return new A.br(a,s,t?null:b.receiver)},
eR(a){if(a==null)return new A.c6(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.an(a,a.dartException)
return A.hJ(a)},
an(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
hJ(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.k.a7(s,16)&8191)===10)switch(r){case 438:return A.an(a,A.dA(A.t(t)+" (Error "+r+")",null))
case 445:case 5007:A.t(t)
return A.an(a,new A.aW())}}if(a instanceof TypeError){q=$.eU()
p=$.eV()
o=$.eW()
n=$.eX()
m=$.f_()
l=$.f0()
k=$.eZ()
$.eY()
j=$.f2()
i=$.f1()
h=q.D(t)
if(h!=null)return A.an(a,A.dA(A.ab(t),h))
else{h=p.D(t)
if(h!=null){h.method="call"
return A.an(a,A.dA(A.ab(t),h))}else if(o.D(t)!=null||n.D(t)!=null||m.D(t)!=null||l.D(t)!=null||k.D(t)!=null||n.D(t)!=null||j.D(t)!=null||i.D(t)!=null){A.ab(t)
return A.an(a,new A.aW())}}return A.an(a,new A.bM(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.aZ()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.an(a,new A.a3(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.aZ()
return a},
ig(a){if(a==null)return J.bW(a)
if(typeof a=="object")return A.bE(a)
return J.bW(a)},
hP(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.C(0,a[t],a[s])}return b},
hQ(a,b){var t,s=a.length
for(t=0;t<s;++t)b.n(0,a[t])
return b},
fh(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.bJ().constructor.prototype):Object.create(new A.ao(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.e8(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.fd(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.e8(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
fd(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.d("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.fa)}throw A.d("Error in functionType of tearoff")},
fe(a,b,c,d){var t=A.e7
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
e8(a,b,c,d){if(c)return A.fg(a,b,d)
return A.fe(b.length,d,a,b)},
ff(a,b,c,d){var t=A.e7,s=A.fb
switch(b?-1:a){case 0:throw A.d(new A.bH("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
fg(a,b,c){var t,s
if($.e5==null)$.e5=A.e4("interceptor")
if($.e6==null)$.e6=A.e4("receiver")
t=b.length
s=A.ff(t,c,a,b)
return s},
dP(a){return A.fh(a)},
fa(a,b){return A.cf(v.typeUniverse,A.T(a.a),b)},
e7(a){return a.a},
fb(a){return a.b},
e4(a){var t,s,r,q=new A.ao("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.d(A.dw("Field name "+a+" not found."))},
dc(a){return v.getIsolateTag(a)},
i0(a){var t,s,r,q,p,o=A.ab($.eK.$1(a)),n=$.d_[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dh[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.ex($.eI.$2(a,o))
if(r!=null){n=$.d_[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dh[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.di(t)
$.d_[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.dh[o]=t
return t}if(q==="-"){p=A.di(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.eL(a,t)
if(q==="*")throw A.d(A.ek(o))
if(v.leafTags[o]===true){p=A.di(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.eL(a,t)},
eL(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.dT(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
di(a){return J.dT(a,!1,null,!!a.$iJ)},
i2(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.di(t)
else return J.dT(t,c,null,null)},
hW(){if(!0===$.dR)return
$.dR=!0
A.hX()},
hX(){var t,s,r,q,p,o,n,m
$.d_=Object.create(null)
$.dh=Object.create(null)
A.hV()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.eM.$1(p)
if(o!=null){n=A.i2(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
hV(){var t,s,r,q,p,o,n=B.n()
n=A.aw(B.o,A.aw(B.p,A.aw(B.j,A.aw(B.j,A.aw(B.q,A.aw(B.r,A.aw(B.t(B.i),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.eK=new A.de(q)
$.eI=new A.df(p)
$.eM=new A.dg(o)},
aw(a,b){return a(b)||b},
hM(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
ih(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
aA:function aA(){},
B:function B(a,b,c){this.a=a
this.b=b
this.$ti=c},
aY:function aY(){},
c7:function c7(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
aW:function aW(){},
br:function br(a,b,c){this.a=a
this.b=b
this.c=c},
bM:function bM(a){this.a=a},
c6:function c6(a){this.a=a},
a4:function a4(){},
bh:function bh(){},
bK:function bK(){},
bJ:function bJ(){},
ao:function ao(a,b){this.a=a
this.b=b},
bH:function bH(a){this.a=a},
W:function W(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
c0:function c0(a){this.a=a},
c4:function c4(a,b){this.a=a
this.b=b
this.c=null},
ae:function ae(a,b){this.a=a
this.$ti=b},
aN:function aN(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aP:function aP(a,b){this.a=a
this.$ti=b},
aO:function aO(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aL:function aL(a,b){this.a=a
this.$ti=b},
aM:function aM(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
de:function de(a){this.a=a},
df:function df(a){this.a=a},
dg:function dg(a){this.a=a},
ai(a,b,c){if(a>>>0!==a||a>=c)throw A.d(A.cF(b,a))},
ar:function ar(){},
aT:function aT(){},
bu:function bu(){},
as:function as(){},
aR:function aR(){},
aS:function aS(){},
bv:function bv(){},
bw:function bw(){},
bx:function bx(){},
by:function by(){},
bz:function bz(){},
bA:function bA(){},
bB:function bB(){},
aU:function aU(){},
bC:function bC(){},
b4:function b4(){},
b5:function b5(){},
b6:function b6(){},
b7:function b7(){},
dD(a,b){var t=b.c
return t==null?b.c=A.bb(a,"e9",[b.x]):t},
eh(a){var t=a.w
if(t===6||t===7)return A.eh(a.x)
return t===11||t===12},
fw(a){return a.as},
be(a){return A.ce(v.typeUniverse,a,!1)},
aj(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.aj(a0,t,a2,a3)
if(s===t)return a1
return A.er(a0,s,!0)
case 7:t=a1.x
s=A.aj(a0,t,a2,a3)
if(s===t)return a1
return A.eq(a0,s,!0)
case 8:r=a1.y
q=A.av(a0,r,a2,a3)
if(q===r)return a1
return A.bb(a0,a1.x,q)
case 9:p=a1.x
o=A.aj(a0,p,a2,a3)
n=a1.y
m=A.av(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.dF(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.av(a0,k,a2,a3)
if(j===k)return a1
return A.es(a0,l,j)
case 11:i=a1.x
h=A.aj(a0,i,a2,a3)
g=a1.y
f=A.hG(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.ep(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.av(a0,e,a2,a3)
p=a1.x
o=A.aj(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.dG(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.d(A.bg("Attempted to substitute unexpected RTI kind "+a))}},
av(a,b,c,d){var t,s,r,q,p=b.length,o=A.cg(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.aj(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
hH(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.cg(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.aj(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
hG(a,b,c,d){var t,s=b.a,r=A.av(a,s,c,d),q=b.b,p=A.av(a,q,c,d),o=b.c,n=A.hH(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.bP()
t.a=r
t.b=p
t.c=n
return t},
b(a,b){a[v.arrayRti]=b
return a},
eJ(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.hU(t)
return a.$S()}return null},
hY(a,b){var t
if(A.eh(b))if(a instanceof A.a4){t=A.eJ(a)
if(t!=null)return t}return A.T(a)},
T(a){if(a instanceof A.w)return A.o(a)
if(Array.isArray(a))return A.M(a)
return A.dJ(J.S(a))},
M(a){var t=a[v.arrayRti],s=u.b
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
o(a){var t=a.$ti
return t!=null?t:A.dJ(a)},
dJ(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.hh(a,t)},
hh(a,b){var t=a instanceof A.a4?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.fV(v.typeUniverse,t.name)
b.$ccache=s
return s},
hU(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.ce(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
hT(a){return A.ak(A.o(a))},
hF(a){var t=a instanceof A.a4?A.eJ(a):null
if(t!=null)return t
if(u.k.b(a))return J.f9(a).a
if(Array.isArray(a))return A.M(a)
return A.T(a)},
ak(a){var t=a.r
return t==null?a.r=new A.cd(a):t},
U(a){return A.ak(A.ce(v.typeUniverse,a,!1))},
hg(a){var t=this
t.b=A.hE(t)
return t.b(a)},
hE(a){var t,s,r,q,p
if(a===u.K)return A.hn
if(A.al(a))return A.hr
t=a.w
if(t===6)return A.he
if(t===1)return A.eD
if(t===7)return A.hi
s=A.hC(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.al)){a.f="$i"+r
if(r==="f")return A.hl
if(a===u.m)return A.hk
return A.hq}}else if(t===10){q=A.hM(a.x,a.y)
p=q==null?A.eD:q
return p==null?A.ew(p):p}return A.hc},
hC(a){if(a.w===8){if(a===u.S)return A.D
if(a===u.i||a===u.H)return A.hm
if(a===u.N)return A.hp
if(a===u.y)return A.dL}return null},
hf(a){var t=this,s=A.hb
if(A.al(t))s=A.h2
else if(t===u.K)s=A.ew
else if(A.ax(t)){s=A.hd
if(t===u.w)s=A.h_
else if(t===u.v)s=A.ex
else if(t===u.u)s=A.fX
else if(t===u.x)s=A.dH
else if(t===u.I)s=A.fZ
else if(t===u.B)s=A.h1}else if(t===u.S)s=A.F
else if(t===u.N)s=A.ab
else if(t===u.y)s=A.bT
else if(t===u.H)s=A.aa
else if(t===u.i)s=A.fY
else if(t===u.m)s=A.h0
t.a=s
return t.a(a)},
hc(a){var t=this
if(a==null)return A.ax(t)
return A.i_(v.typeUniverse,A.hY(a,t),t)},
he(a){if(a==null)return!0
return this.x.b(a)},
hq(a){var t,s=this
if(a==null)return A.ax(s)
t=s.f
if(a instanceof A.w)return!!a[t]
return!!J.S(a)[t]},
hl(a){var t,s=this
if(a==null)return A.ax(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.w)return!!a[t]
return!!J.S(a)[t]},
hk(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.w)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
eC(a){if(typeof a=="object"){if(a instanceof A.w)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
hb(a){var t=this
if(a==null){if(A.ax(t))return a}else if(t.b(a))return a
throw A.G(A.ez(a,t),new Error())},
hd(a){var t=this
if(a==null||t.b(a))return a
throw A.G(A.ez(a,t),new Error())},
ez(a,b){return new A.b9("TypeError: "+A.el(a,A.N(b,null)))},
el(a,b){return A.bl(a)+": type '"+A.N(A.hF(a),null)+"' is not a subtype of type '"+b+"'"},
Q(a,b){return new A.b9("TypeError: "+A.el(a,b))},
hi(a){var t=this
return t.x.b(a)||A.dD(v.typeUniverse,t).b(a)},
hn(a){return a!=null},
ew(a){if(a!=null)return a
throw A.G(A.Q(a,"Object"),new Error())},
hr(a){return!0},
h2(a){return a},
eD(a){return!1},
dL(a){return!0===a||!1===a},
bT(a){if(!0===a)return!0
if(!1===a)return!1
throw A.G(A.Q(a,"bool"),new Error())},
fX(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.G(A.Q(a,"bool?"),new Error())},
fY(a){if(typeof a=="number")return a
throw A.G(A.Q(a,"double"),new Error())},
fZ(a){if(typeof a=="number")return a
if(a==null)return a
throw A.G(A.Q(a,"double?"),new Error())},
D(a){return typeof a=="number"&&Math.floor(a)===a},
F(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.G(A.Q(a,"int"),new Error())},
h_(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.G(A.Q(a,"int?"),new Error())},
hm(a){return typeof a=="number"},
aa(a){if(typeof a=="number")return a
throw A.G(A.Q(a,"num"),new Error())},
dH(a){if(typeof a=="number")return a
if(a==null)return a
throw A.G(A.Q(a,"num?"),new Error())},
hp(a){return typeof a=="string"},
ab(a){if(typeof a=="string")return a
throw A.G(A.Q(a,"String"),new Error())},
ex(a){if(typeof a=="string")return a
if(a==null)return a
throw A.G(A.Q(a,"String?"),new Error())},
h0(a){if(A.eC(a))return a
throw A.G(A.Q(a,"JSObject"),new Error())},
h1(a){if(a==null)return a
if(A.eC(a))return a
throw A.G(A.Q(a,"JSObject?"),new Error())},
eH(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.N(a[r],b)
return t},
hz(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.eH(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.N(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
eA(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.b([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.a.n(a3,"T"+(s+r))
for(q=u.O,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.A(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.N(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.N(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.N(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.N(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.N(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
N(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.N(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.N(a.x,b)+">"
if(m===8){q=A.hI(a.x)
p=a.y
return p.length>0?q+("<"+A.eH(p,b)+">"):q}if(m===10)return A.hz(a,b)
if(m===11)return A.eA(a,b,null)
if(m===12)return A.eA(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.A(b,o)
return b[o]}return"?"},
hI(a){var t=A.eP(a)
if(t!=null)return t
return"minified:"+a},
fW(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
fV(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.ce(a,b,!1)
else if(typeof n=="number"){t=n
s=A.bc(a,5,"#")
r=A.cg(t)
for(q=0;q<t;++q)r[q]=s
p=A.bb(a,b,r)
o[b]=p
return p}else return n},
fT(a,b){return A.eu(a.tR,b)},
fS(a,b){return A.eu(a.eT,b)},
ce(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.et(a,null,b,!1)
s.set(b,t)
return t},
cf(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.et(a,b,c,!0)
r.set(c,s)
return s},
fU(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.dF(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
et(a,b,c,d){return A.fL(A.fF(a,b,c,d))},
a9(a,b){b.a=A.hf
b.b=A.hg
return b},
bc(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.R(null,null)
t.w=b
t.as=c
s=A.a9(a,t)
a.eC.set(c,s)
return s},
er(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.fQ(a,b,s,c)
a.eC.set(s,t)
return t},
fQ(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.al(b))if(!(b===u.a||b===u.T))if(t!==6)s=t===7&&A.ax(b.x)
if(s)return b
else if(t===1)return u.a}r=new A.R(null,null)
r.w=6
r.x=b
r.as=c
return A.a9(a,r)},
eq(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.fO(a,b,s,c)
a.eC.set(s,t)
return t},
fO(a,b,c,d){var t,s
if(d){t=b.w
if(A.al(b)||b===u.K)return b
else if(t===1)return A.bb(a,"e9",[b])
else if(b===u.a||b===u.T)return u.W}s=new A.R(null,null)
s.w=7
s.x=b
s.as=c
return A.a9(a,s)},
fR(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.R(null,null)
t.w=13
t.x=b
t.as=r
s=A.a9(a,t)
a.eC.set(r,s)
return s},
ba(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
fN(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
bb(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.ba(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.R(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.a9(a,s)
a.eC.set(q,r)
return r},
dF(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.ba(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.R(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.a9(a,p)
a.eC.set(r,o)
return o},
es(a,b,c){var t,s,r="+"+(b+"("+A.ba(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.R(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.a9(a,t)
a.eC.set(r,s)
return s},
ep(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.ba(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.ba(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.fN(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.R(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.a9(a,q)
a.eC.set(s,p)
return p},
dG(a,b,c,d){var t,s=b.as+("<"+A.ba(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.fP(a,b,c,s,d)
a.eC.set(s,t)
return t},
fP(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.cg(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.aj(a,b,s,0)
n=A.av(a,c,s,0)
return A.dG(a,o,n,c!==n)}}m=new A.R(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.a9(a,m)},
fF(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
fL(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.fH(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.en(a,s,m,l,!1)
else if(r===46)s=A.en(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.ah(a.u,a.e,l.pop()))
break
case 94:l.push(A.fR(a.u,l.pop()))
break
case 35:l.push(A.bc(a.u,5,"#"))
break
case 64:l.push(A.bc(a.u,2,"@"))
break
case 126:l.push(A.bc(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.fJ(a,l)
break
case 38:A.fI(a,l)
break
case 63:q=a.u
l.push(A.er(q,A.ah(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.eq(q,A.ah(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.fG(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.eo(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.fM(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-2)
break
case 43:o=m.indexOf("(",s)
l.push(m.substring(s,o))
l.push(-4)
l.push(a.p)
a.p=l.length
s=o+1
break
default:throw"Bad character "+r}}}n=l.pop()
return A.ah(a.u,a.e,n)},
fH(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
en(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.fW(t,p.x)[q]
if(o==null)A.ds('No "'+q+'" in "'+A.fw(p)+'"')
d.push(A.cf(t,p,o))}else d.push(q)
return n},
fJ(a,b){var t,s=a.u,r=A.em(a,b),q=b.pop()
if(typeof q=="string")b.push(A.bb(s,q,r))
else{t=A.ah(s,a.e,q)
switch(t.w){case 11:b.push(A.dG(s,t,r,a.n))
break
default:b.push(A.dF(s,t,r))
break}}},
fG(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.em(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.ah(q,a.e,p)
r=new A.bP()
r.a=t
r.b=o
r.c=n
b.push(A.ep(q,s,r))
return
case-4:b.push(A.es(q,b.pop(),t))
return
default:throw A.d(A.bg("Unexpected state under `()`: "+A.t(p)))}},
fI(a,b){var t=b.pop()
if(0===t){b.push(A.bc(a.u,1,"0&"))
return}if(1===t){b.push(A.bc(a.u,4,"1&"))
return}throw A.d(A.bg("Unexpected extended operation "+A.t(t)))},
em(a,b){var t=b.splice(a.p)
A.eo(a.u,a.e,t)
a.p=b.pop()
return t},
ah(a,b,c){if(typeof c=="string")return A.bb(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.fK(a,b,c)}else return c},
eo(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.ah(a,b,c[t])},
fM(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.ah(a,b,c[t])},
fK(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.d(A.bg("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.d(A.bg("Bad index "+c+" for "+b.k(0)))},
i_(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.z(a,b,null,c,null)
s.set(c,t)}return t},
z(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.al(d))return!0
t=b.w
if(t===4)return!0
if(A.al(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.z(a,c[b.x],c,d,e))return!0
r=d.w
q=u.a
if(b===q||b===u.T){if(r===7)return A.z(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.z(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.z(a,b.x,c,d,e))return!1
return A.z(a,A.dD(a,b),c,d,e)}if(t===6)return A.z(a,q,c,d,e)&&A.z(a,b.x,c,d,e)
if(r===7){if(A.z(a,b,c,d.x,e))return!0
return A.z(a,b,c,A.dD(a,d),e)}if(r===6)return A.z(a,b,c,q,e)||A.z(a,b,c,d.x,e)
if(s)return!1
q=t!==11
if((!q||t===12)&&d===u.Z)return!0
p=t===10
if(p&&d===u.V)return!0
if(r===12){if(b===u.L)return!0
if(t!==12)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.z(a,k,c,j,e)||!A.z(a,j,e,k,c))return!1}return A.eB(a,b.x,c,d.x,e)}if(r===11){if(b===u.L)return!0
if(q)return!1
return A.eB(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.hj(a,b,c,d,e)}if(p&&r===10)return A.ho(a,b,c,d,e)
return!1},
eB(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.z(a2,a3.x,a4,a5.x,a6))return!1
t=a3.y
s=a5.y
r=t.a
q=s.a
p=r.length
o=q.length
if(p>o)return!1
n=o-p
m=t.b
l=s.b
k=m.length
j=l.length
if(p+k<o+j)return!1
for(i=0;i<p;++i){h=r[i]
if(!A.z(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.z(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.z(a2,l[i],a6,h,a4))return!1}g=t.c
f=s.c
e=g.length
d=f.length
for(c=0,b=0;b<d;b+=3){a=f[b]
for(;;){if(c>=e)return!1
a0=g[c]
c+=3
if(a<a0)return!1
a1=g[c-2]
if(a0<a){if(a1)return!1
continue}h=f[b+1]
if(a1&&!h)return!1
h=g[c-1]
if(!A.z(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
hj(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.cf(a,b,s[p])
return A.ev(a,q,null,c,d.y,e)}return A.ev(a,b.y,null,c,d.y,e)},
ev(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.z(a,b[t],d,e[t],f))return!1
return!0},
ho(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.z(a,s[t],c,r[t],e))return!1
return!0},
ax(a){var t=a.w,s=!0
if(!(a===u.a||a===u.T))if(!A.al(a))if(t!==6)s=t===7&&A.ax(a.x)
return s},
al(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.O},
eu(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
cg(a){return a>0?new Array(a):v.typeUniverse.sEA},
R:function R(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
bP:function bP(){this.c=this.b=this.a=null},
cd:function cd(a){this.a=a},
bO:function bO(){},
b9:function b9(a){this.a=a},
fo(a,b){return new A.W(a.i("@<0>").E(b).i("W<1,2>"))},
i(a,b,c){return b.i("@<0>").E(c).i("eb<1,2>").a(A.hP(a,new A.W(b.i("@<0>").E(c).i("W<1,2>"))))},
fp(a,b){return new A.W(a.i("@<0>").E(b).i("W<1,2>"))},
dB(a){return new A.af(a.i("af<0>"))},
fq(a,b){return b.i("ec<0>").a(A.hQ(a,new A.af(b.i("af<0>"))))},
dE(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
fE(a,b,c){var t=new A.ag(a,b,c.i("ag<0>"))
t.c=a.e
return t},
fr(a,b){var t,s,r=A.dB(b)
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.dW)(a),++s)r.n(0,b.a(a[s]))
return r},
dC(a){var t,s
if(A.dS(a))return"{...}"
t=new A.au("")
try{s={}
B.a.n($.O,a)
t.a+="{"
s.a=!0
a.K(0,new A.c5(s,t))
t.a+="}"}finally{if(0>=$.O.length)return A.A($.O,-1)
$.O.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
af:function af(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
bS:function bS(a){this.a=a
this.b=null},
ag:function ag(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
j:function j(){},
L:function L(){},
c5:function c5(a,b){this.a=a
this.b=b},
at:function at(){},
b8:function b8(){},
hy(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.eR(s)
r=String(t)
throw A.d(new A.bX(r))}r=A.cm(q)
return r},
cm(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.bQ(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.cm(a[t])
return a},
ea(a,b,c){return new A.aK(a,b)},
h6(a){return a.aG()},
fC(a,b){return new A.ca(a,[],A.hL())},
fD(a,b,c){var t,s=new A.au(""),r=A.fC(s,b)
r.S(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
bQ:function bQ(a,b){this.a=a
this.b=b
this.c=null},
bR:function bR(a){this.a=a},
bi:function bi(){},
bk:function bk(){},
aK:function aK(a,b){this.a=a
this.b=b},
bs:function bs(a,b){this.a=a
this.b=b},
c1:function c1(){},
c3:function c3(a){this.b=a},
c2:function c2(a){this.a=a},
cb:function cb(){},
cc:function cc(a,b){this.a=a
this.b=b},
ca:function ca(a,b,c){this.c=a
this.a=b
this.b=c},
ed(a,b,c){var t,s,r
if(a>4294967295)A.ds(A.bG(a,0,4294967295,"length",null))
t=A.b(new Array(a),c.i("v<0>"))
t.$flags=1
s=t
if(a!==0&&b!=null)for(t=s.length,r=0;r<t;++r)s[r]=b
return s},
ft(a,b){var t,s=A.b([],b.i("v<0>"))
for(t=J.a1(a);t.l();)B.a.n(s,b.a(t.gm()))
return s},
ee(a,b){var t=A.fs(a,b)
return t},
fs(a,b){var t,s
if(Array.isArray(a))return A.b(a.slice(0),b.i("v<0>"))
t=A.b([],b.i("v<0>"))
for(s=J.a1(a);s.l();)B.a.n(t,s.gm())
return t},
ei(a,b,c){var t=J.a1(b)
if(!t.l())return a
if(c.length===0){do a+=A.t(t.gm())
while(t.l())}else{a+=A.t(t.gm())
while(t.l())a=a+c+A.t(t.gm())}return a},
bl(a){if(typeof a=="number"||A.dL(a)||a==null)return J.ay(a)
if(typeof a=="string")return JSON.stringify(a)
return A.fu(a)},
bg(a){return new A.bf(a)},
dw(a){return new A.a3(!1,null,null,a)},
bG(a,b,c,d,e){return new A.aX(b,c,!0,a,d,"Invalid value")},
fv(a,b,c){if(a>c)throw A.d(A.bG(a,0,c,"start",null))
if(a>b||b>c)throw A.d(A.bG(b,a,c,"end",null))
return b},
eg(a,b){if(a<0)throw A.d(A.bG(a,0,null,b,null))
return a},
dx(a,b,c,d){return new A.bm(b,!0,a,d,"Index out of range")},
ek(a){return new A.bL(a)},
H(a){return new A.bj(a)},
fn(a,b,c){var t,s
if(A.dS(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.b([],u.s)
B.a.n($.O,a)
try{A.hs(a,t)}finally{if(0>=$.O.length)return A.A($.O,-1)
$.O.pop()}s=A.ei(b,u.U.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
dy(a,b,c){var t,s
if(A.dS(a))return b+"..."+c
t=new A.au(b)
B.a.n($.O,a)
try{s=t
s.a=A.ei(s.a,a,", ")}finally{if(0>=$.O.length)return A.A($.O,-1)
$.O.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
hs(a,b){var t,s,r,q,p,o,n,m=a.gp(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.l())return
t=A.t(m.gm())
B.a.n(b,t)
l+=t.length+2;++k}if(!m.l()){if(k<=5)return
if(0>=b.length)return A.A(b,-1)
s=b.pop()
if(0>=b.length)return A.A(b,-1)
r=b.pop()}else{q=m.gm();++k
if(!m.l()){if(k<=4){B.a.n(b,A.t(q))
return}s=A.t(q)
if(0>=b.length)return A.A(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gm();++k
for(;m.l();q=p,p=o){o=m.gm();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.A(b,-1)
l-=b.pop().length+2;--k}B.a.n(b,"...")
return}}r=A.t(q)
s=A.t(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.A(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.n(b,n)
B.a.n(b,r)
B.a.n(b,s)},
u:function u(){},
bf:function bf(a){this.a=a},
b_:function b_(){},
a3:function a3(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aX:function aX(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bm:function bm(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bN:function bN(a){this.a=a},
bL:function bL(a){this.a=a},
bI:function bI(a){this.a=a},
bj:function bj(a){this.a=a},
aZ:function aZ(){},
bX:function bX(a){this.a=a},
c:function c(){},
a7:function a7(a,b,c){this.a=a
this.b=b
this.$ti=c},
aV:function aV(){},
w:function w(){},
au:function au(a){this.a=a},
bV(a,b){var t,s,r,q,p=J.y(a)
if(p.gj(a)===b.length){t=p.gj(a)
s=J.bZ(t,u.y)
for(r=0;r<t;++r){q=p.h(a,r)
if(!(r<b.length))return A.A(b,r)
s[r]=J.h(q,b[r])}p=B.a.u(s,new A.cE())}else p=!1
return p},
eN(a,b){var t,s,r,q,p,o,n=A.ft(b,u.S)
for(t=a.$ti,s=new A.Y(a,a.gj(0),t.i("Y<j.E>")),t=t.i("j.E");s.l();){r=s.d
if(r==null)r=t.a(r)
if(r<0||r>2)throw A.d(A.dw("Comparator ngo\xe0i b\u1ed1n d\xe2y"))
q=n.length
if(r>>>0!==r||r>=q)return A.A(n,r)
p=n[r]
o=r+1
if(!(o<q))return A.A(n,o)
q=n[o]
if(p>q){n[r]=q
n[o]=p}}return n},
cE:function cE(){},
cO:function cO(){},
cN:function cN(){},
cG:function cG(){},
cP:function cP(){},
cQ:function cQ(){},
cM:function cM(){},
cS:function cS(){},
cT:function cT(){},
cU:function cU(){},
cK:function cK(){},
cL:function cL(a){this.a=a},
cV:function cV(){},
cW:function cW(){},
cX:function cX(){},
cJ:function cJ(){},
cY:function cY(){},
cH:function cH(){},
cI:function cI(){},
cZ:function cZ(){},
cR:function cR(){},
d0:function d0(){},
d1:function d1(){},
d2:function d2(){},
p(a,b,c,d,e,f,g,h,i,j,k,l){return new A.q(e,g,f,l,b,a)},
P:function P(a,b,c){this.a=a
this.c=b
this.d=c},
q:function q(a,b,c,d,e,f){var _=this
_.a=a
_.f=b
_.r=c
_.w=d
_.y=e
_.at=f},
dK(a,b){var t,s,r,q=!1
if(u.j.b(a)){t=J.y(a)
if(t.gj(a)===3){s=J.bZ(3,u.y)
for(r=0;r<3;++r)s[r]=J.h(t.h(a,r),b[r])
q=B.a.u(s,new A.co())}}return q},
dN(a,b,c,d){var t=""+c,s=u.N,r=u.z
return A.p(A.i(["extra",c,"total",d],s,r),null,"B\u1edbt "+t+" \u1edf c\u1ea3 hai v\u1ebf b\u1ea3o to\xe0n \u0111\u1eb3ng th\u1ee9c: x = "+(d-c)+". Gi\xe1 tr\u1ecb thay \u0111\u1ed5i, quy t\u1eafc c\xe2n b\u1eb1ng v\u1eabn gi\u1eef nguy\xean.","Quan s\xe1t l\u01b0\u1ee3ng c\xf2n c\u1ed9ng v\u1edbi x. M\u1ed7i thao t\xe1c ph\u1ea3i gi\u1eef hai v\u1ebf b\u1eb1ng nhau.",a,A.i(["pairs",0],s,r),"removeBothSides","M\xf4 h\xecnh \u0111ang bi\u1ec3u di\u1ec5n x + "+t+" = "+d+". Gi\u1eef c\xe2n b\u1eb1ng v\xe0 c\xf4 l\u1eadp x b\u1eb1ng c\xe1ch b\u1ecf c\xf9ng m\u1ed9t l\u01b0\u1ee3ng \u1edf hai v\u1ebf.",B.c,"V\u1eadn d\u1ee5ng",b,new A.cA(c))},
eF(a,b,c,d){return A.p(B.b,null,"Ph\u1ea7n t\xf4 l\xe0 "+d+"/8; ph\u1ea7n ch\u01b0a t\xf4 l\xe0 "+(8-d)+"/8. M\u1ed9t t\u1ed5ng th\u1ec3 cho ph\xe9p di\u1ec5n t\u1ea3 c\u1ea3 ph\u1ea7n v\xe0 ph\u1ea7n b\xf9.","\u0110\u1ed5i v\u1ec1 nh\u1eefng ph\u1ea7n c\xf3 m\u1eabu s\u1ed1 8. C\xf3 th\u1ec3 ch\u1ea1m l\u1ea1i \u0111\u1ec3 b\u1ecf m\xe0u m\u1ed9t l\xe1t.",a,A.i(["painted",A.b([],u.t)],u.N,u.z),"fractionPaint",c+" T\u1ef1 t\xf4 tr\xean chi\u1ebfc b\xe1nh chia 8 l\xe1t b\u1eb1ng nhau.",B.c,"V\u1eadn d\u1ee5ng",b,new A.cw(d))},
dM(a,b,c,d){return A.p(B.b,null,"T\u1ed5ng qu\xe3ng \u0111\u01b0\u1eddng b\u1eb1ng t\u1ed5ng di\u1ec7n t\xedch d\u01b0\u1edbi t\u1eebng \u0111o\u1ea1n t\u1ed1c \u0111\u1ed9. C\xf9ng m\u1ed9t qu\xe3ng \u0111\u01b0\u1eddng c\xf3 th\u1ec3 c\xf3 nhi\u1ec1u l\u1ecbch tr\xecnh; c\xe1c \u0111i\u1ec1u ki\u1ec7n ph\u1ee5 quy\u1ebft \u0111\u1ecbnh l\u1ecbch tr\xecnh ph\xf9 h\u1ee3p.","Qu\xe3ng \u0111\u01b0\u1eddng m\u1ed7i \xf4 = t\u1ed1c \u0111\u1ed9 \xd7 2. Th\u1eddi gian ngh\u1ec9 v\u1eabn tr\xf4i, nh\u01b0ng qu\xe3ng \u0111\u01b0\u1eddng kh\xf4ng t\u0103ng.",a,A.i(["segments",A.b([-1,-1,-1],u.t)],u.N,u.z),"motionTimeline",c+" M\u1ed7i \xf4 d\xe0i 2 gi\xe2y; \u0111i ch\u1eadm 1 m/s, \u0111i nhanh 2 m/s. Gh\xe9p th\u1ebb r\u1ed3i \u0111\u1ecdc \u0111\u01b0\u1eddng \u0111i.",B.c,"Th\u1eed th\xe1ch",b,new A.ct(d))},
dI(a,b,c,d,e){return A.p(B.b,null,"T\u1ed5ng "+B.a.aA(c,new A.ck())+" t\u1ea7ng kh\xf4ng \u0111\u1ed5i sau m\u1ed7i l\u1ea7n chuy\u1ec3n. M\xf4 h\xecnh "+B.a.a0(e," \u2013 ")+" th\u1ecfa \u0111\u1ed3ng th\u1eddi t\u1ed5ng v\xe0 c\xe1c quan h\u1ec7 \u0111\u1ec1 b\xe0i.","T\u1ed5ng s\u1ed1 t\u1ea7ng \u0111\u01b0\u1ee3c b\u1ea3o to\xe0n. D\xf9ng t\u1ed5ng v\xe0 quan h\u1ec7 gi\u1eefa c\xe1c t\xf2a \u0111\u1ec3 t\xecm m\xf4 h\xecnh ph\xf9 h\u1ee3p.",a,A.i(["heights",c],u.N,u.z),"redistributeMean",d+" Chuy\u1ec3n t\u1ea7ng gi\u1eefa ba t\xf2a; kh\xf4ng \u0111\u01b0\u1ee3c th\xeam hay b\u1ecf t\u1ea7ng.",B.c,"Th\u1eed th\xe1ch",b,new A.cl(e))},
eG(a,b,c,d){var t=""+c,s=u.t
return A.p(B.b,null,"Di\u1ec7n t\xedch r\xe0ng bu\u1ed9c t\xedch hai c\u1ea1nh; chu vi r\xe0ng bu\u1ed9c t\u1ed5ng hai c\u1ea1nh. M\u1ed9t m\xf4 h\xecnh ph\u1ea3i \u0111\xe1p \u1ee9ng c\u1ea3 hai \u0111i\u1ec1u ki\u1ec7n.","T\xecm hai c\u1ea1nh v\u1eeba c\xf3 t\xedch b\u1eb1ng "+t+", v\u1eeba c\xf3 t\u1ed5ng b\u1eb1ng "+(d/2|0)+". Kh\xf4ng ch\u1ec9 ki\u1ec3m tra di\u1ec7n t\xedch.",a,A.i(["points",A.b([A.b([0,0],s),A.b([4,0],s),A.b([4,4],s),A.b([0,4],s)],u.p)],u.N,u.z),"polygonVertices","K\xe9o b\u1ed1n \u0111\u1ec9nh th\xe0nh h\xecnh ch\u1eef nh\u1eadt c\xf3 di\u1ec7n t\xedch "+t+" \xf4 vu\xf4ng v\xe0 chu vi "+d+" \u0111\u01a1n v\u1ecb. M\u1ed7i kho\u1ea3ng l\u01b0\u1edbi d\xe0i 1 \u0111\u01a1n v\u1ecb.",B.c,"Th\u1eed th\xe1ch",b,new A.cz(c,d))},
dO(a,b,c,d){var t=d==null?"":" Tr\u01b0\u1edbc khi t\u1edbi \u0111\xedch, ph\u1ea3i qua c\u1ed9t "+(d[0]+1)+", h\xe0ng "+(d[1]+1)+" (\u0111\u1ebfm t\u1eeb g\xf3c tr\xe1i tr\xean).",s=c.length===0?"":" \u0110\u01b0\u1eddng hi\u1ec7n t\u1ea1i c\xf3 l\u1ed7i: d\xf9ng n\xfat l\xf9i \u0111\u1ec3 s\u1eeda."
return A.p(B.b,null,"Thu\u1eadt to\xe1n t\u1ed1t v\u1eeba \u0111i \u0111\xfang, v\u1eeba tu\xe2n th\u1ee7 gi\u1edbi h\u1ea1n t\xe0i nguy\xean. \u0110\u01b0\u1eddng \u0111i c\u1ee7a b\u1ea1n v\u01b0\u1ee3t qua \u0111\xe1, \u0111\u1ebfn \u0111\xedch v\xe0 \u0111\xe1p \u1ee9ng gi\u1edbi h\u1ea1n 6 l\u1ec7nh.","M\u1ed7i b\u01b0\u1edbc ch\u1ec9 thay \u0111\u1ed5i m\u1ed9t t\u1ecda \u0111\u1ed9. Quan s\xe1t \u0111\u01b0\u1eddng v\u1ebd v\xe0 lo\u1ea1i c\xe1c b\u01b0\u1edbc v\xf2ng l\u1ea1i kh\xf4ng c\u1ea7n thi\u1ebft.",a,A.i(["commands",c],u.N,u.z),"robotRoute","D\u1eabn robot t\u1edbi sao b\u1eb1ng t\u1ed1i \u0111a 6 l\u1ec7nh, tr\xe1nh \u0111\xe1 v\xe0 m\xe9p b\u1ea3n \u0111\u1ed3."+t+s,B.c,"Th\u1eed th\xe1ch",b,new A.cB(6,d))},
eE(a,b,c,d,e){var t,s,r="M\u1eabu "+c,q=A.M(e)
q=new A.aQ(e,q.i("a(1)").a(new A.cq()),q.i("aQ<1,a>")).a0(0,"% \u2013 ")
t=u.N
s=u.z
return A.p(A.i(["color",d,"colorLabel",r],t,s),null,r+" \u0111\u01b0\u1ee3c t\u1ea1o b\u1edfi m\u1ee9c \u0111\u1ecf\u2013l\u1ee5c\u2013lam "+q+"%. C\u1ed9ng c\xe1c ch\xf9m s\xe1ng thay \u0111\u1ed5i c\u1ea3 s\u1eafc v\xe0 \u0111\u1ed9 s\xe1ng.","Th\u1eed b\u1eadt t\u1eebng c\u1eb7p ngu\u1ed3n, r\u1ed3i c\u1ea3 ba ngu\u1ed3n. \u0110\xe2y l\xe0 pha \xe1nh s\xe1ng c\u1ed9ng, kh\xf4ng ph\u1ea3i pha s\u01a1n.",a,A.i(["rgb",A.b([0,0,0],u.n)],t,s),"colorMixer","\u0110i\u1ec1u ch\u1ec9nh ba ngu\u1ed3n s\xe1ng \u0111\u1ec3 kh\u1edbp m\u1eabu "+c+". Quan s\xe1t m\xe0u tr\u1ed9n khi t\u0103ng ho\u1eb7c gi\u1ea3m t\u1eebng ngu\u1ed3n.",B.c,"V\u1eadn d\u1ee5ng",b,new A.cr(e))},
ey(a,b,c,d,e){var t=""+c,s=""+d,r=u.N,q=u.z
return A.p(A.i(["capacity",c],r,q),null,"C\xf3 "+s+" vi\xean xanh v\xe0 "+(c-d)+" vi\xean \u0111\u1ecf, n\xean P(xanh) = "+s+"/"+t+". C\u01a1 h\u1ed9i thay \u0111\u1ed5i khi t\u1ec9 l\u1ec7 c\xe1c m\xe0u thay \u0111\u1ed5i.","Hai m\xe0u chia s\u1ebb c\xf9ng m\u1ed9t t\u1ed5ng. Chuy\u1ec3n \u0111i\u1ec1u ki\u1ec7n \u0111\u1ec1 b\xe0i th\xe0nh s\u1ed1 vi\xean c\u1ee7a t\u1eebng m\xe0u r\u1ed3i ki\u1ec3m tra l\u1ea1i c\u1ea3 t\xfai.",a,A.i(["balls",A.b([],u.s)],r,q),"probabilityBag",e+" D\u1ef1ng t\xfai g\u1ed3m \u0111\xfang "+t+" vi\xean b\u1eb1ng c\xe1ch th\xeam ho\u1eb7c l\u1ea5y bi ra.",B.c,"Th\u1eed th\xe1ch",b,new A.cj(c,d))},
co:function co(){},
cA:function cA(a){this.a=a},
cw:function cw(a){this.a=a},
cu:function cu(){},
ct:function ct(a){this.a=a},
cs:function cs(){},
ck:function ck(){},
cl:function cl(a){this.a=a},
cz:function cz(a,b){this.a=a
this.b=b},
cy:function cy(){},
cx:function cx(){},
cB:function cB(a,b){this.a=a
this.b=b},
cq:function cq(){},
cr:function cr(a){this.a=a},
cp:function cp(){},
cj:function cj(a,b){this.a=a
this.b=b},
ch:function ch(){},
ci:function ci(){},
d8:function d8(){},
d9:function d9(){},
da:function da(){},
db:function db(){},
d6:function d6(){},
d7:function d7(){},
hN(a){var t,s,r=u.P.a(a).h(0,"position")
if(!A.D(r)||r<0||r>8)return B.d
t=r===6
s=A.b(["valid-position"],u.s)
if(t)s.push("equivalent-fraction")
return new A.P(t,s,t?"fraction-match":"fraction-position")},
hO(a){var t,s,r=u.P.a(a).h(0,"painted")
if(u.j.b(r)){t=J.a0(r)
t=t.I(r,new A.d3())||t.G(r).a!==t.gj(r)}else t=!0
if(t)return B.d
s=J.a2(r)===3
t=A.b(["valid-slices"],u.s)
if(s)t.push("target-fraction")
return new A.P(s,t,s?"fraction-match":"fraction-count")},
d3:function d3(){},
h3(a){return J.h(u.P.a(a).h(0,"blocks"),4)},
hA(a){return J.h(u.P.a(a).h(0,"pairs"),3)},
ha(a){return J.h(u.P.a(a).h(0,"turns"),2)},
hx(a){var t,s=u.P.a(a).h(0,"painted")
if(u.j.b(s)){t=J.y(s)
t=t.gj(s)===3&&t.G(s).a===3&&t.u(s,new A.cv())}else t=!1
return t},
h9(a){return J.h(u.P.a(a).h(0,"folds"),2)},
h8(a){return A.bU(u.P.a(a).h(0,"baskets"),A.b([3,3,3],u.t))},
ht(a){var t
u.P.a(a)
t=A.dH(a.h(0,"angle"))
return Math.abs((t==null?0:t)-45)<=3&&J.h(a.h(0,"launched"),!0)},
hw(a){return A.bU(u.P.a(a).h(0,"segments"),A.b([2,0,1],u.t))},
hu(a){return J.h(u.P.a(a).h(0,"position"),3)},
hD(a){return A.bU(u.P.a(a).h(0,"order"),A.b([1,2,3,4],u.t))},
h4(a){return A.bU(u.P.a(a).h(0,"bins"),A.b([0,0,1,1,2,2],u.t))},
hv(a){return A.bU(u.P.a(a).h(0,"heights"),A.b([4,4,4],u.t))},
bU(a,b){var t,s,r,q,p,o=!1
if(u.j.b(a)){t=J.y(a)
s=t.gj(a)
r=b.length
if(s===r){q=J.bZ(r,u.y)
for(p=0;p<r;++p){o=t.h(a,p)
if(!(p<b.length))return A.A(b,p)
q[p]=J.h(o,b[p])}o=B.a.u(q,new A.cn())}}return o},
cv:function cv(){},
cn:function cn(){},
hB(a){var t,s,r,q,p,o,n,m,l
A.ab(a)
try{p=u.P
t=p.a(B.f.ao(a,null))
o=$.f3()
n=A.o(o).i("aP<2>")
s=new A.aC(new A.aP(o,n),n.i("c<q>(c.E)").a(new A.cC()),n.i("aC<c.E,q>")).au(0,new A.cD(t))
r=p.a(J.r(t,"state"))
q=s.ar(r)
p=q.a
q.toString
m=B.f.a8(A.i(["is_correct",p,"misconception_codes",B.c,"satisfied_constraints",q.c,"feedback_key",q.d,"mechanism",s.f,"evaluator_version",1,"config",s.at,"initial_state",s.r],u.N,u.K),null)
return m}catch(l){p=u.N
m=B.f.a8(A.i(["error","unsupported_activity_or_invalid_state"],p,p),null)
return m}},
i1(){var t,s=v.G.globalThis
if(typeof A.dU()=="function")A.ds(A.dw("Attempting to rewrap a JS function."))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.h5,A.dU())
t[$.dZ()]=A.dU()
return s.matlingoEvaluate=t},
cC:function cC(){},
cD:function cD(a){this.a=a},
dj:function dj(){},
dk:function dk(){},
dl:function dl(){},
dm:function dm(){},
dn:function dn(){},
dp:function dp(){},
dq:function dq(){},
dr:function dr(){},
dY(a){return B.a.u(A.b(["width","height","depth"],u.s),new A.du(a))},
dV(a){return A.F(a.h(0,"width"))*A.F(a.h(0,"height"))*A.F(a.h(0,"depth"))},
eO(a){var t=A.F(a.h(0,"width")),s=A.F(a.h(0,"height")),r=A.F(a.h(0,"depth"))
return 2*(t*s+t*r+s*r)},
eS(a){var t
if(u.j.b(a)){t=J.y(a)
t=t.gj(a)===3&&t.u(a,new A.dt())&&J.h(t.h(a,0),10)&&J.h(t.h(a,1),20)&&J.h(t.h(a,2),30)}else t=!1
return t},
du:function du(a){this.a=a},
dt:function dt(){},
d4(a,b){var t,s,r,q,p,o,n,m,l,k,j,i="volume",h="solid-match",g="volume-mismatch",f="latitude",e="longitude",d=a==="geometry-solid-volume"
if(d||a==="algebra-solid-relation"){if(!A.dY(b))return B.d
t=A.dV(b)
s=A.b([],u.s)
if(d){if(t===12)B.a.n(s,i)
if(A.eO(b)===32)B.a.n(s,"surface")
d=s.length===2
if(d)r=h
else r=B.a.J(s,i)?"surface-mismatch":g
return new A.P(d,s,r)}if(t===16)B.a.n(s,i)
if(J.h(b.h(0,"width"),2*A.aa(b.h(0,"height"))))B.a.n(s,"double-height")
if(J.h(b.h(0,"depth"),b.h(0,"height")))B.a.n(s,"equal-depth")
d=s.length===3
if(d)r=h
else r=B.a.J(s,i)?"relation-mismatch":g
return new A.P(d,s,r)}if(a==="geography-globe-grid"){q=b.h(0,f)
p=b.h(0,e)
if(!A.D(q)||!A.D(p)||q<-90||q>90||p<-180||p>180)return B.d
d=A.b([],u.s)
r=q===15
if(r)d.push(f)
if(p===105)d.push(e)
o=d.length===2
if(o)r="coordinate-match"
else r=!r?"latitude-mismatch":"longitude-mismatch"
return new A.P(o,d,r)}n=b.h(0,"layers")
d=!0
if(a==="geography-rock-layers")if(u.j.b(n)){d=J.y(n)
d=d.gj(n)!==3||d.G(n).a!==3||d.I(n,new A.d5())}if(d)return B.d
m=A.eS(n)
d=A.b([],u.s)
for(r=J.a0(n),l=0;l<2;l=k){o=r.h(n,l)
k=l+1
j=r.h(n,k)
if(typeof o!=="number")return o.aF()
if(typeof j!=="number")return A.dd(j)
if(o<j)d.push("order-"+l)}return new A.P(m,d,m?"layers-match":"layer-order-mismatch")},
d5:function d5(){},
eP(a){return v.mangledGlobalNames[a]},
ii(a){throw A.G(new A.bt("Field '"+a+"' has been assigned during initialization."),new Error())},
h5(a,b,c){u.Z.a(a)
if(A.F(c)>=1)return a.$1(b)
return a.$0()}},B={}
var w=[A,J,B]
var $={}
A.dz.prototype={}
J.bn.prototype={
v(a,b){return a===b},
gA(a){return A.bE(a)},
k(a){return"Instance of '"+A.bF(a)+"'"},
gt(a){return A.ak(A.dJ(this))}}
J.bp.prototype={
k(a){return String(a)},
gA(a){return a?519018:218159},
gt(a){return A.ak(u.y)},
$im:1,
$il:1}
J.aF.prototype={
v(a,b){return null==b},
k(a){return"null"},
gA(a){return 0},
$im:1}
J.aI.prototype={$ix:1}
J.a6.prototype={
gA(a){return 0},
k(a){return String(a)}}
J.bD.prototype={}
J.b0.prototype={}
J.a5.prototype={
k(a){var t=a[$.eT()]
if(t==null)t=a[$.dZ()]
if(t==null)return this.af(a)
return"JavaScript function for "+J.ay(t)},
$iap:1}
J.aH.prototype={
gA(a){return 0},
k(a){return String(a)}}
J.aJ.prototype={
gA(a){return 0},
k(a){return String(a)}}
J.v.prototype={
R(a,b){return new A.V(a,A.M(a).i("@<1>").E(b).i("V<1,2>"))},
n(a,b){A.M(a).c.a(b)
a.$flags&1&&A.dX(a,29)
a.push(b)},
M(a,b){var t=A.M(a)
return new A.a_(a,t.i("l(1)").a(b),t.i("a_<1>"))},
F(a,b){var t
A.M(a).i("c<1>").a(b)
a.$flags&1&&A.dX(a,"addAll",2)
if(Array.isArray(b)){this.ah(a,b)
return}for(t=J.a1(b);t.l();)a.push(t.gm())},
ah(a,b){var t,s
u.b.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.d(A.H(a))
for(s=0;s<t;++s)a.push(b[s])},
a0(a,b){var t,s=A.ed(a.length,"",u.N)
for(t=0;t<a.length;++t)this.C(s,t,A.t(a[t]))
return s.join(b)},
aA(a,b){var t,s,r
A.M(a).i("1(1,1)").a(b)
t=a.length
if(t===0)throw A.d(A.bY())
if(0>=t)return A.A(a,0)
s=a[0]
for(r=1;r<t;++r){s=b.$2(s,a[r])
if(t!==a.length)throw A.d(A.H(a))}return s},
B(a,b){if(!(b>=0&&b<a.length))return A.A(a,b)
return a[b]},
gaz(a){var t=a.length
if(t>0)return a[t-1]
throw A.d(A.bY())},
I(a,b){var t,s
A.M(a).i("l(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(b.$1(a[s]))return!0
if(a.length!==t)throw A.d(A.H(a))}return!1},
u(a,b){var t,s
A.M(a).i("l(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(!b.$1(a[s]))return!1
if(a.length!==t)throw A.d(A.H(a))}return!0},
J(a,b){var t
for(t=0;t<a.length;++t)if(J.h(a[t],b))return!0
return!1},
gq(a){return a.length===0},
gL(a){return a.length!==0},
k(a){return A.dy(a,"[","]")},
G(a){return A.fr(a,A.M(a).c)},
gp(a){return new J.ac(a,a.length,A.M(a).i("ac<1>"))},
gA(a){return A.bE(a)},
gj(a){return a.length},
h(a,b){if(!(b>=0&&b<a.length))throw A.d(A.cF(a,b))
return a[b]},
C(a,b,c){A.M(a).c.a(c)
a.$flags&2&&A.dX(a)
if(!(b>=0&&b<a.length))throw A.d(A.cF(a,b))
a[b]=c},
$ie:1,
$ic:1,
$if:1}
J.bo.prototype={
aB(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.bF(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.c_.prototype={}
J.ac.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
l(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.dW(r)
throw A.d(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0},
$iC:1}
J.aG.prototype={
k(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gA(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
a7(a,b){var t
if(a>0)t=this.am(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
am(a,b){return b>31?0:a>>>b},
gt(a){return A.ak(u.H)},
$ik:1,
$iam:1}
J.aE.prototype={
gt(a){return A.ak(u.S)},
$im:1,
$ia:1}
J.bq.prototype={
gt(a){return A.ak(u.i)},
$im:1}
J.aq.prototype={
O(a,b,c){return a.substring(b,A.fv(b,c,a.length))},
k(a){return a},
gA(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gt(a){return A.ak(u.N)},
gj(a){return a.length},
$im:1,
$in:1}
A.a8.prototype={
gp(a){return new A.az(J.a1(this.gH()),A.o(this).i("az<1,2>"))},
gj(a){return J.a2(this.gH())},
gq(a){return J.f7(this.gH())},
gL(a){return J.f8(this.gH())},
B(a,b){return A.o(this).y[1].a(J.e2(this.gH(),b))},
k(a){return J.ay(this.gH())}}
A.az.prototype={
l(){return this.a.l()},
gm(){return this.$ti.y[1].a(this.a.gm())},
$iC:1}
A.ad.prototype={
gH(){return this.a}}
A.b3.prototype={$ie:1}
A.b2.prototype={
h(a,b){return this.$ti.y[1].a(J.r(this.a,b))},
$ie:1,
$if:1}
A.V.prototype={
R(a,b){return new A.V(this.a,this.$ti.i("@<1>").E(b).i("V<1,2>"))},
gH(){return this.a}}
A.bt.prototype={
k(a){return"LateInitializationError: "+this.a}}
A.e.prototype={}
A.X.prototype={
gp(a){var t=this
return new A.Y(t,t.gj(t),A.o(t).i("Y<X.E>"))},
gq(a){return this.gj(this)===0},
a0(a,b){var t,s,r,q=this,p=q.gj(q)
if(b.length!==0){if(p===0)return""
t=A.t(q.B(0,0))
if(p!==q.gj(q))throw A.d(A.H(q))
for(s=t,r=1;r<p;++r){s=s+b+A.t(q.B(0,r))
if(p!==q.gj(q))throw A.d(A.H(q))}return s.charCodeAt(0)==0?s:s}else{for(r=0,s="";r<p;++r){s+=A.t(q.B(0,r))
if(p!==q.gj(q))throw A.d(A.H(q))}return s.charCodeAt(0)==0?s:s}}}
A.Y.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
l(){var t,s=this,r=s.a,q=J.y(r),p=q.gj(r)
if(s.b!==p)throw A.d(A.H(r))
t=s.c
if(t>=p){s.d=null
return!1}s.d=q.B(r,t);++s.c
return!0},
$iC:1}
A.aQ.prototype={
gj(a){return J.a2(this.a)},
B(a,b){return this.b.$1(J.e2(this.a,b))}}
A.a_.prototype={
gp(a){return new A.b1(J.a1(this.a),this.b,this.$ti.i("b1<1>"))}}
A.b1.prototype={
l(){var t,s
for(t=this.a,s=this.b;t.l();)if(s.$1(t.gm()))return!0
return!1},
gm(){return this.a.gm()},
$iC:1}
A.aC.prototype={
gp(a){return new A.aD(J.a1(this.a),this.b,B.m,this.$ti.i("aD<1,2>"))}}
A.aD.prototype={
gm(){var t=this.d
return t==null?this.$ti.y[1].a(t):t},
l(){var t,s,r=this,q=r.c
if(q==null)return!1
for(t=r.a,s=r.b;!q.l();){r.d=null
if(t.l()){r.c=null
q=J.a1(s.$1(t.gm()))
r.c=q}else return!1}r.d=r.c.gm()
return!0},
$iC:1}
A.aB.prototype={
l(){return!1},
gm(){throw A.d(A.bY())},
$iC:1}
A.I.prototype={}
A.bd.prototype={}
A.aA.prototype={
gq(a){return this.gj(this)===0},
k(a){return A.dC(this)},
$iK:1}
A.B.prototype={
gj(a){return this.b.length},
gak(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
an(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
h(a,b){if(!this.an(b))return null
return this.b[this.a[b]]},
K(a,b){var t,s,r,q
this.$ti.i("~(1,2)").a(b)
t=this.gak()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])}}
A.aY.prototype={}
A.c7.prototype={
D(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
if(q==null)return null
t=Object.create(null)
s=r.b
if(s!==-1)t.arguments=q[s+1]
s=r.c
if(s!==-1)t.argumentsExpr=q[s+1]
s=r.d
if(s!==-1)t.expr=q[s+1]
s=r.e
if(s!==-1)t.method=q[s+1]
s=r.f
if(s!==-1)t.receiver=q[s+1]
return t}}
A.aW.prototype={
k(a){return"Null check operator used on a null value"}}
A.br.prototype={
k(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.bM.prototype={
k(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.c6.prototype={
k(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.a4.prototype={
k(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.eQ(s==null?"unknown":s)+"'"},
$iap:1,
gaE(){return this},
$C:"$1",
$R:1,
$D:null}
A.bh.prototype={$C:"$2",$R:2}
A.bK.prototype={}
A.bJ.prototype={
k(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.eQ(t)+"'"}}
A.ao.prototype={
v(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.ao))return!1
return this.$_target===b.$_target&&this.a===b.a},
gA(a){return(A.ig(this.a)^A.bE(this.$_target))>>>0},
k(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.bF(this.a)+"'")}}
A.bH.prototype={
k(a){return"RuntimeError: "+this.a}}
A.W.prototype={
gj(a){return this.a},
gq(a){return this.a===0},
gN(){return new A.ae(this,A.o(this).i("ae<1>"))},
F(a,b){A.o(this).i("K<1,2>").a(b).K(0,new A.c0(this))},
h(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.av(b)},
av(a){var t,s,r=this.d
if(r==null)return null
t=this.aj(r,a)
s=this.aa(t,a)
if(s<0)return null
return t[s].b},
C(a,b,c){var t,s,r=this,q=A.o(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.a2(t==null?r.b=r.X():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.a2(s==null?r.c=r.X():s,b,c)}else r.aw(b,c)},
aw(a,b){var t,s,r,q,p=this,o=A.o(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.X()
s=p.a9(a)
r=t[s]
if(r==null)t[s]=[p.Y(a,b)]
else{q=p.aa(r,a)
if(q>=0)r[q].b=b
else r.push(p.Y(a,b))}},
K(a,b){var t,s,r=this
A.o(r).i("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.d(A.H(r))
t=t.c}},
a2(a,b,c){var t,s=A.o(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.Y(b,c)
else t.b=c},
Y(a,b){var t=this,s=A.o(t),r=new A.c4(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else t.f=t.f.c=r;++t.a
t.r=t.r+1&1073741823
return r},
a9(a){return J.bW(a)&1073741823},
aj(a,b){return a[this.a9(b)]},
aa(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.h(a[s].a,b))return s
return-1},
k(a){return A.dC(this)},
X(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$ieb:1}
A.c0.prototype={
$2(a,b){var t=this.a,s=A.o(t)
t.C(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.o(this.a).i("~(1,2)")}}
A.c4.prototype={}
A.ae.prototype={
gj(a){return this.a.a},
gq(a){return this.a.a===0},
gp(a){var t=this.a
return new A.aN(t,t.r,t.e,this.$ti.i("aN<1>"))}}
A.aN.prototype={
gm(){return this.d},
l(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.d(A.H(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}},
$iC:1}
A.aP.prototype={
gj(a){return this.a.a},
gq(a){return this.a.a===0},
gp(a){var t=this.a
return new A.aO(t,t.r,t.e,this.$ti.i("aO<1>"))}}
A.aO.prototype={
gm(){return this.d},
l(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.d(A.H(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.b
s.c=t.c
return!0}},
$iC:1}
A.aL.prototype={
gj(a){return this.a.a},
gq(a){return this.a.a===0},
gp(a){var t=this.a
return new A.aM(t,t.r,t.e,this.$ti.i("aM<1,2>"))}}
A.aM.prototype={
gm(){var t=this.d
t.toString
return t},
l(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.d(A.H(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=new A.a7(t.a,t.b,s.$ti.i("a7<1,2>"))
s.c=t.c
return!0}},
$iC:1}
A.de.prototype={
$1(a){return this.a(a)},
$S:4}
A.df.prototype={
$2(a,b){return this.a(a,b)},
$S:7}
A.dg.prototype={
$1(a){return this.a(A.ab(a))},
$S:8}
A.ar.prototype={
gt(a){return B.an},
$im:1}
A.aT.prototype={}
A.bu.prototype={
gt(a){return B.ao},
$im:1}
A.as.prototype={
gj(a){return a.length},
$iJ:1}
A.aR.prototype={
h(a,b){A.ai(b,a,a.length)
return a[b]},
$ie:1,
$ic:1,
$if:1}
A.aS.prototype={$ie:1,$ic:1,$if:1}
A.bv.prototype={
gt(a){return B.ap},
$im:1}
A.bw.prototype={
gt(a){return B.aq},
$im:1}
A.bx.prototype={
gt(a){return B.ar},
h(a,b){A.ai(b,a,a.length)
return a[b]},
$im:1}
A.by.prototype={
gt(a){return B.as},
h(a,b){A.ai(b,a,a.length)
return a[b]},
$im:1}
A.bz.prototype={
gt(a){return B.at},
h(a,b){A.ai(b,a,a.length)
return a[b]},
$im:1}
A.bA.prototype={
gt(a){return B.au},
h(a,b){A.ai(b,a,a.length)
return a[b]},
$im:1}
A.bB.prototype={
gt(a){return B.av},
h(a,b){A.ai(b,a,a.length)
return a[b]},
$im:1}
A.aU.prototype={
gt(a){return B.aw},
gj(a){return a.length},
h(a,b){A.ai(b,a,a.length)
return a[b]},
$im:1}
A.bC.prototype={
gt(a){return B.ax},
gj(a){return a.length},
h(a,b){A.ai(b,a,a.length)
return a[b]},
$im:1}
A.b4.prototype={}
A.b5.prototype={}
A.b6.prototype={}
A.b7.prototype={}
A.R.prototype={
i(a){return A.cf(v.typeUniverse,this,a)},
E(a){return A.fU(v.typeUniverse,this,a)}}
A.bP.prototype={}
A.cd.prototype={
k(a){return A.N(this.a,null)}}
A.bO.prototype={
k(a){return this.a}}
A.b9.prototype={}
A.af.prototype={
gp(a){var t=this,s=new A.ag(t,t.r,A.o(t).i("ag<1>"))
s.c=t.e
return s},
gj(a){return this.a},
gq(a){return this.a===0},
gL(a){return this.a!==0},
J(a,b){var t,s
if(typeof b=="string"&&b!=="__proto__"){t=this.b
if(t==null)return!1
return u.g.a(t[b])!=null}else if(typeof b=="number"&&(b&1073741823)===b){s=this.c
if(s==null)return!1
return u.g.a(s[b])!=null}else return this.ai(b)},
ai(a){var t=this.d
if(t==null)return!1
return this.a5(t[this.a4(a)],a)>=0},
n(a,b){var t,s,r=this
A.o(r).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.a3(t==null?r.b=A.dE():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.a3(s==null?r.c=A.dE():s,b)}else return r.ag(b)},
ag(a){var t,s,r,q=this
A.o(q).c.a(a)
t=q.d
if(t==null)t=q.d=A.dE()
s=q.a4(a)
r=t[s]
if(r==null)t[s]=[q.U(a)]
else{if(q.a5(r,a)>=0)return!1
r.push(q.U(a))}return!0},
a3(a,b){A.o(this).c.a(b)
if(u.g.a(a[b])!=null)return!1
a[b]=this.U(b)
return!0},
U(a){var t=this,s=new A.bS(A.o(t).c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
a4(a){return J.bW(a)&1073741823},
a5(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.h(a[s].a,b))return s
return-1},
$iec:1}
A.bS.prototype={}
A.ag.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
l(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.d(A.H(r))
else if(s==null){t.d=null
return!1}else{t.d=t.$ti.i("1?").a(s.a)
t.c=s.b
return!0}},
$iC:1}
A.j.prototype={
gp(a){return new A.Y(a,this.gj(a),A.T(a).i("Y<j.E>"))},
B(a,b){return this.h(a,b)},
gq(a){return this.gj(a)===0},
gL(a){return!this.gq(a)},
u(a,b){var t,s
A.T(a).i("l(j.E)").a(b)
t=this.gj(a)
for(s=0;s<t;++s){if(!b.$1(this.h(a,s)))return!1
if(t!==this.gj(a))throw A.d(A.H(a))}return!0},
I(a,b){var t,s
A.T(a).i("l(j.E)").a(b)
t=this.gj(a)
for(s=0;s<t;++s){if(b.$1(this.h(a,s)))return!0
if(t!==this.gj(a))throw A.d(A.H(a))}return!1},
M(a,b){var t=A.T(a)
return new A.a_(a,t.i("l(j.E)").a(b),t.i("a_<j.E>"))},
G(a){var t,s=A.dB(A.T(a).i("j.E"))
for(t=0;t<this.gj(a);++t)s.n(0,this.h(a,t))
return s},
R(a,b){return new A.V(a,A.T(a).i("@<j.E>").E(b).i("V<1,2>"))},
k(a){return A.dy(a,"[","]")}}
A.L.prototype={
K(a,b){var t,s,r,q=A.o(this)
q.i("~(L.K,L.V)").a(b)
for(t=this.gN(),t=t.gp(t),q=q.i("L.V");t.l();){s=t.gm()
r=this.h(0,s)
b.$2(s,r==null?q.a(r):r)}},
gj(a){var t=this.gN()
return t.gj(t)},
gq(a){var t=this.gN()
return t.gq(t)},
k(a){return A.dC(this)},
$iK:1}
A.c5.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.t(a)
s.a=(s.a+=t)+": "
t=A.t(b)
s.a+=t},
$S:5}
A.at.prototype={
gq(a){return this.a===0},
gL(a){return this.a!==0},
F(a,b){var t
A.o(this).i("c<1>").a(b)
for(t=b.gp(b);t.l();)this.n(0,t.gm())},
Z(a){var t,s
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.dW)(a),++s)if(!this.J(0,a[s]))return!1
return!0},
k(a){return A.dy(this,"{","}")},
B(a,b){var t,s,r,q=this
A.eg(b,"index")
t=A.fE(q,q.r,A.o(q).c)
for(s=b;t.l();){if(s===0){r=t.d
return r==null?t.$ti.c.a(r):r}--s}throw A.d(A.dx(b,b-s,q,"index"))},
$ie:1,
$ic:1}
A.b8.prototype={}
A.bQ.prototype={
h(a,b){var t,s=this.b
if(s==null)return this.c.h(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.al(b):t}},
gj(a){return this.b==null?this.c.a:this.P().length},
gq(a){return this.gj(0)===0},
gN(){if(this.b==null){var t=this.c
return new A.ae(t,A.o(t).i("ae<1>"))}return new A.bR(this)},
K(a,b){var t,s,r,q,p=this
u.E.a(b)
if(p.b==null)return p.c.K(0,b)
t=p.P()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.cm(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.d(A.H(p))}},
P(){var t=u.Y.a(this.c)
if(t==null)t=this.c=A.b(Object.keys(this.a),u.s)
return t},
al(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.cm(this.a[a])
return this.b[a]=t}}
A.bR.prototype={
gj(a){return this.a.gj(0)},
B(a,b){var t=this.a
if(t.b==null)t=t.gN().B(0,b)
else{t=t.P()
if(!(b>=0&&b<t.length))return A.A(t,b)
t=t[b]}return t},
gp(a){var t=this.a
if(t.b==null){t=t.gN()
t=t.gp(t)}else{t=t.P()
t=new J.ac(t,t.length,A.M(t).i("ac<1>"))}return t}}
A.bi.prototype={}
A.bk.prototype={}
A.aK.prototype={
k(a){var t=A.bl(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.bs.prototype={
k(a){return"Cyclic error in JSON stringify"}}
A.c1.prototype={
ao(a,b){var t=A.hy(a,this.gap().a)
return t},
a8(a,b){var t=A.fD(a,this.gaq().b,null)
return t},
gaq(){return B.L},
gap(){return B.K}}
A.c3.prototype={}
A.c2.prototype={}
A.cb.prototype={
ac(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.e.O(a,s,r)
s=r+1
p=A.E(92)
t.a+=p
p=A.E(117)
t.a+=p
p=A.E(100)
t.a+=p
p=q>>>8&15
p=A.E(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.E(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.E(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.e.O(a,s,r)
s=r+1
p=A.E(92)
t.a+=p
switch(q){case 8:p=A.E(98)
t.a+=p
break
case 9:p=A.E(116)
t.a+=p
break
case 10:p=A.E(110)
t.a+=p
break
case 12:p=A.E(102)
t.a+=p
break
case 13:p=A.E(114)
t.a+=p
break
default:p=A.E(117)
t.a+=p
p=A.E(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.E(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.E(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.e.O(a,s,r)
s=r+1
p=A.E(92)
t.a+=p
p=A.E(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.e.O(a,s,n)},
T(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.d(new A.bs(a,null))}B.a.n(t,a)},
S(a){var t,s,r,q,p=this
if(p.ab(a))return
p.T(a)
try{t=p.b.$1(a)
if(!p.ab(t)){r=A.ea(a,null,p.ga6())
throw A.d(r)}r=p.a
if(0>=r.length)return A.A(r,-1)
r.pop()}catch(q){s=A.eR(q)
r=A.ea(a,s,p.ga6())
throw A.d(r)}},
ab(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.H.k(a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.ac(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.T(a)
r.aC(a)
t=r.a
if(0>=t.length)return A.A(t,-1)
t.pop()
return!0}else if(u.f.b(a)){r.T(a)
s=r.aD(a)
t=r.a
if(0>=t.length)return A.A(t,-1)
t.pop()
return s}else return!1},
aC(a){var t,s,r=this.c
r.a+="["
t=J.a0(a)
if(t.gL(a)){this.S(t.h(a,0))
for(s=1;s<t.gj(a);++s){r.a+=","
this.S(t.h(a,s))}}r.a+="]"},
aD(a){var t,s,r,q,p,o,n=this,m={}
if(a.gq(a)){n.c.a+="{}"
return!0}t=a.gj(a)*2
s=A.ed(t,null,u.O)
r=m.a=0
m.b=!0
a.K(0,new A.cc(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.ac(A.ab(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.A(s,o)
n.S(s[o])}q.a+="}"
return!0}}
A.cc.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.C(t,s.a++,a)
B.a.C(t,s.a++,b)},
$S:5}
A.ca.prototype={
ga6(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.u.prototype={}
A.bf.prototype={
k(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bl(t)
return"Assertion failed"}}
A.b_.prototype={}
A.a3.prototype={
gW(){return"Invalid argument"+(!this.a?"(s)":"")},
gV(){return""},
k(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.gW()+r+p
if(!t.a)return o
return o+t.gV()+": "+A.bl(t.ga_())},
ga_(){return this.b}}
A.aX.prototype={
ga_(){return A.dH(this.b)},
gW(){return"RangeError"},
gV(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.t(r):""
else if(r==null)t=": Not greater than or equal to "+A.t(s)
else if(r>s)t=": Not in inclusive range "+A.t(s)+".."+A.t(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.t(s)
return t}}
A.bm.prototype={
ga_(){return A.F(this.b)},
gW(){return"RangeError"},
gV(){if(A.F(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gj(a){return this.f}}
A.bN.prototype={
k(a){return"Unsupported operation: "+this.a}}
A.bL.prototype={
k(a){return"UnimplementedError: "+this.a}}
A.bI.prototype={
k(a){return"Bad state: "+this.a}}
A.bj.prototype={
k(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bl(t)+"."}}
A.aZ.prototype={
k(a){return"Stack Overflow"},
$iu:1}
A.bX.prototype={
k(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException"
return s}}
A.c.prototype={
R(a,b){return A.fc(this,A.o(this).i("c.E"),b)},
M(a,b){var t=A.o(this)
return new A.a_(this,t.i("l(c.E)").a(b),t.i("a_<c.E>"))},
u(a,b){var t
A.o(this).i("l(c.E)").a(b)
for(t=this.gp(this);t.l();)if(!b.$1(t.gm()))return!1
return!0},
I(a,b){var t
A.o(this).i("l(c.E)").a(b)
for(t=this.gp(this);t.l();)if(b.$1(t.gm()))return!0
return!1},
G(a){var t=A.dB(A.o(this).i("c.E"))
t.F(0,this)
return t},
gj(a){var t,s=this.gp(this)
for(t=0;s.l();)++t
return t},
gq(a){return!this.gp(this).l()},
gL(a){return!this.gq(this)},
au(a,b){var t,s
A.o(this).i("l(c.E)").a(b)
for(t=this.gp(this);t.l();){s=t.gm()
if(b.$1(s))return s}throw A.d(A.bY())},
B(a,b){var t,s
A.eg(b,"index")
t=this.gp(this)
for(s=b;t.l();){if(s===0)return t.gm();--s}throw A.d(A.dx(b,b-s,this,"index"))},
k(a){return A.fn(this,"(",")")}}
A.a7.prototype={
k(a){return"MapEntry("+A.t(this.a)+": "+A.t(this.b)+")"}}
A.aV.prototype={
gA(a){return A.w.prototype.gA.call(this,0)},
k(a){return"null"}}
A.w.prototype={$iw:1,
v(a,b){return this===b},
gA(a){return A.bE(this)},
k(a){return"Instance of '"+A.bF(this)+"'"},
gt(a){return A.hT(this)},
toString(){return this.k(this)}}
A.au.prototype={
gj(a){return this.a.length},
k(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ifx:1}
A.cE.prototype={
$1(a){return A.bT(a)},
$S:3}
A.cO.prototype={
$1(a){var t,s,r,q,p,o=u.j,n=J.dv(o.a(u.P.a(a).h(0,"points")),o)
o=n.a
t=J.y(o)
s=!1
if(t.gj(o)===4)if(n.u(n,new A.cN())){r=n.$ti.y[1]
if(J.h(J.r(r.a(t.h(o,0)),1),J.r(r.a(t.h(o,1)),1)))if(J.h(J.r(r.a(t.h(o,1)),0),J.r(r.a(t.h(o,2)),0)))if(J.h(J.r(r.a(t.h(o,2)),1),J.r(r.a(t.h(o,3)),1)))if(J.h(J.r(r.a(t.h(o,3)),0),J.r(r.a(t.h(o,0)),0))){s=J.r(r.a(t.h(o,1)),0)
q=J.r(r.a(t.h(o,0)),0)
if(typeof s!=="number")return s.a1()
if(typeof q!=="number")return A.dd(q)
p=J.r(r.a(t.h(o,3)),1)
o=J.r(r.a(t.h(o,0)),1)
if(typeof p!=="number")return p.a1()
if(typeof o!=="number")return A.dd(o)
o=Math.abs((s-q)*(p-o))===6}else o=s
else o=s
else o=s
else o=s}else o=s
else o=s
return o},
$S:0}
A.cN.prototype={
$1(a){var t
u.j.a(a)
t=J.y(a)
return t.gj(a)===2&&t.u(a,new A.cG())},
$S:6}
A.cG.prototype={
$1(a){return A.D(a)&&a>=0&&a<=4},
$S:1}
A.cP.prototype={
$1(a){var t,s
u.P.a(a)
t=u.j
s=J.e3(t.a(a.h(0,"cells")))
return J.a2(t.a(a.h(0,"cells")))===3&&s.a===3&&s.Z([11,16,23])},
$S:0}
A.cQ.prototype={
$1(a){var t,s,r,q
u.P.a(a)
t=u.j
s=t.a(a.h(0,"turns"))
r=J.y(s)
q=!1
if(r.gj(s)===2)if(r.u(s,new A.cM())){q=r.h(s,0)
r=r.h(s,1)
if(typeof q!=="number")return q.a1()
if(typeof r!=="number")return A.dd(r)
t=Math.abs(q-r)===2&&A.bV(t.a(a.h(0,"placed")),[!0,!0])}else t=q
else t=q
return t},
$S:0}
A.cM.prototype={
$1(a){return A.D(a)&&a>=0&&a<4},
$S:1}
A.cS.prototype={
$1(a){var t,s,r,q,p,o,n="commands"
u.P.a(a)
t=u.j
if(J.a2(t.a(a.h(0,n)))>32)return!1
for(t=J.a1(t.a(a.h(0,n))),s=u.s,r=0,q=0;t.l();){p=t.gm()
if(!B.a.J(A.b(["R","L","D","U"],s),p))return!1
o=J.S(p)
if(o.v(p,"R"))++r
if(o.v(p,"L"))--r
if(o.v(p,"D"))++q
if(o.v(p,"U"))--q
o=!0
if(r>=0)if(r<=3)if(q>=0)if(q<=3)o=r===1&&q===1
if(o)return!1}return r===3&&q===3},
$S:0}
A.cT.prototype={
$1(a){u.P.a(a)
return A.bV(u.j.a(a.h(0,"body")),["R","D"])&&J.h(a.h(0,"repeat"),3)},
$S:0}
A.cU.prototype={
$1(a){var t,s
u.P.a(a)
t=u.j
s=J.dv(t.a(a.h(0,"stages")),u.S)
if(s.gj(0)===0||J.a2(s.a)>6||s.I(s,new A.cK()))return!1
return A.bV(t.a(a.h(0,"result")),A.eN(s,A.b([4,1,3,2],u.t)))&&B.a.u($.f5(),new A.cL(s))},
$S:0}
A.cK.prototype={
$1(a){A.F(a)
return a<0||a>2},
$S:9}
A.cL.prototype={
$1(a){return A.bV(A.eN(this.a,u.M.a(a)),[1,2,3,4])},
$S:10}
A.cV.prototype={
$1(a){var t
u.P.a(a)
t=u.j
return J.a2(t.a(a.h(0,"edges")))===2&&J.e3(t.a(a.h(0,"edges"))).Z(["0-1","2-3"])},
$S:0}
A.cW.prototype={
$1(a){return A.bV(u.j.a(u.P.a(a).h(0,"switches")),[!1,!0,!0])},
$S:0}
A.cX.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"rgb")),s=J.y(t)
return s.gj(t)===3&&s.u(t,new A.cJ())&&A.aa(s.h(t,0))>0.95&&A.aa(s.h(t,1))>0.95&&A.aa(s.h(t,2))<0.05},
$S:0}
A.cJ.prototype={
$1(a){return typeof a=="number"&&a>=0&&a<=1},
$S:1}
A.cY.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"balls")),s=J.y(t)
return s.gj(t)===6&&s.M(t,new A.cH()).gj(0)===2&&s.M(t,new A.cI()).gj(0)===4},
$S:0}
A.cH.prototype={
$1(a){return J.h(a,"B")},
$S:1}
A.cI.prototype={
$1(a){return J.h(a,"R")},
$S:1}
A.cZ.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"outcomes")),s=J.y(t)
return s.gj(t)===4&&s.G(t).Z(["SS","SN","NS","NN"])},
$S:0}
A.cR.prototype={
$1(a){return J.h(u.P.a(a).h(0,"sectors"),3)},
$S:0}
A.d0.prototype={
$1(a){var t="position"
u.P.a(a)
return A.D(a.h(0,t))&&J.h(a.h(0,t),6)},
$S:0}
A.d1.prototype={
$1(a){u.P.a(a)
return J.h(a.h(0,"a"),!0)&&J.h(a.h(0,"b"),!1)},
$S:0}
A.d2.prototype={
$1(a){var t,s,r="outlier"
u.P.a(a)
t=!1
if(A.D(a.h(0,r))){s=a.h(0,r)
if(typeof s!=="number")return s.ad()
if(s>=10){t=a.h(0,r)
if(typeof t!=="number")return t.ae()
t=t<=15}}return t},
$S:0}
A.P.prototype={}
A.q.prototype={
ar(a){var t,s
u.P.a(a)
try{t=this.y
t=t==null?null:t.$1(a)
if(t==null)t=new A.P(this.w.$1(a),B.c,"try-again")
return t}catch(s){return B.d}}}
A.co.prototype={
$1(a){return A.bT(a)},
$S:3}
A.cA.prototype={
$1(a){return J.h(u.P.a(a).h(0,"pairs"),this.a)},
$S:0}
A.cw.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"painted")),s=J.y(t),r=this.a
return s.gj(t)===r&&s.G(t).a===r&&s.u(t,new A.cu())},
$S:0}
A.cu.prototype={
$1(a){return A.D(a)&&a>=0&&a<8},
$S:1}
A.ct.prototype={
$1(a){var t,s
u.P.a(a)
t=u.j.a(a.h(0,"segments"))
s=J.y(t)
return s.gj(t)===3&&s.u(t,new A.cs())&&this.a.$1(a)},
$S:0}
A.cs.prototype={
$1(a){return A.D(a)&&a>=0&&a<=2},
$S:1}
A.ck.prototype={
$2(a,b){return A.F(a)+A.F(b)},
$S:11}
A.cl.prototype={
$1(a){return A.dK(u.P.a(a).h(0,"heights"),this.a)},
$S:0}
A.cz.prototype={
$1(a){var t,s,r,q,p=u.j,o=J.dv(p.a(u.P.a(a).h(0,"points")),p)
p=o.a
t=J.y(p)
if(t.gj(p)!==4||o.I(o,new A.cy()))return!1
s=o.$ti.y[1]
r=Math.abs(A.F(J.r(s.a(t.h(p,1)),0))-A.F(J.r(s.a(t.h(p,0)),0)))
q=Math.abs(A.F(J.r(s.a(t.h(p,3)),1))-A.F(J.r(s.a(t.h(p,0)),1)))
return J.h(J.r(s.a(t.h(p,0)),1),J.r(s.a(t.h(p,1)),1))&&J.h(J.r(s.a(t.h(p,1)),0),J.r(s.a(t.h(p,2)),0))&&J.h(J.r(s.a(t.h(p,2)),1),J.r(s.a(t.h(p,3)),1))&&J.h(J.r(s.a(t.h(p,3)),0),J.r(s.a(t.h(p,0)),0))&&r*q===this.a&&2*(r+q)===this.b},
$S:0}
A.cy.prototype={
$1(a){var t
u.j.a(a)
t=J.y(a)
return t.gj(a)!==2||t.I(a,new A.cx())},
$S:6}
A.cx.prototype={
$1(a){return!A.D(a)||a<0||a>4},
$S:1}
A.cB.prototype={
$1(a){var t,s,r,q,p,o,n,m,l=u.j.a(u.P.a(a).h(0,"commands")),k=J.y(l)
if(k.gq(l)||k.gj(l)>this.a)return!1
t=this.b
s=t==null
for(k=k.gp(l),r=!s,q=u.s,p=0,o=0;k.l();){n=k.gm()
if(!B.a.J(A.b(["R","L","D","U"],q),n))return!1
m=J.S(n)
if(m.v(n,"R"))++p
if(m.v(n,"L"))--p
if(m.v(n,"D"))++o
if(m.v(n,"U"))--o
m=!0
if(p>=0)if(p<=3)if(o>=0)if(o<=3)m=p===1&&o===1
if(m)return!1
if(r&&p===t[0]&&o===t[1])s=!0}return p===3&&o===3&&s},
$S:0}
A.cq.prototype={
$1(a){return A.F(a)*100},
$S:12}
A.cr.prototype={
$1(a){var t,s,r,q=u.j.a(u.P.a(a).h(0,"rgb")),p=J.y(q)
if(p.gj(q)===3){t=J.bZ(3,u.y)
for(s=this.a,r=0;r<3;++r)t[r]=typeof p.h(q,r)=="number"&&A.aa(p.h(q,r))>=0&&A.aa(p.h(q,r))<=1&&Math.abs(A.aa(p.h(q,r))-s[r])<0.05
p=B.a.u(t,new A.cp())}else p=!1
return p},
$S:0}
A.cp.prototype={
$1(a){return A.bT(a)},
$S:3}
A.cj.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"balls")),s=J.y(t)
return s.gj(t)===this.a&&s.u(t,new A.ch())&&s.M(t,new A.ci()).gj(0)===this.b},
$S:0}
A.ch.prototype={
$1(a){var t=J.S(a)
return t.v(a,"B")||t.v(a,"R")},
$S:1}
A.ci.prototype={
$1(a){return J.h(a,"B")},
$S:1}
A.d8.prototype={
$1(a){return J.h(u.P.a(a).h(0,"blocks"),6)},
$S:0}
A.d9.prototype={
$1(a){return A.dK(u.P.a(a).h(0,"segments"),A.b([2,2,0],u.t))},
$S:0}
A.da.prototype={
$1(a){return A.dK(u.P.a(a).h(0,"segments"),A.b([1,0,2],u.t))},
$S:0}
A.db.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"segments")),s=J.a0(t)
return s.M(t,new A.d6()).gj(0)===1&&s.M(t,new A.d7()).gj(0)===2},
$S:0}
A.d6.prototype={
$1(a){return J.h(a,2)},
$S:1}
A.d7.prototype={
$1(a){return J.h(a,0)},
$S:1}
A.d3.prototype={
$1(a){return!A.D(a)||a<0||a>=8},
$S:1}
A.cv.prototype={
$1(a){return A.D(a)&&a>=0&&a<8},
$S:1}
A.cn.prototype={
$1(a){return A.bT(a)},
$S:3}
A.cC.prototype={
$1(a){return u.X.a(a)},
$S:13}
A.cD.prototype={
$1(a){var t=this.a
return u.A.a(a).a===t.h(0,"activity_id")&&1===t.h(0,"content_version")},
$S:14}
A.dj.prototype={
$1(a){return A.d4("geography-globe-grid",u.P.a(a))},
$S:2}
A.dk.prototype={
$1(a){var t="latitude",s="longitude"
u.P.a(a)
return A.D(a.h(0,t))&&A.D(a.h(0,s))&&J.h(a.h(0,t),15)&&J.h(a.h(0,s),105)},
$S:0}
A.dl.prototype={
$1(a){return A.d4("geography-rock-layers",u.P.a(a))},
$S:2}
A.dm.prototype={
$1(a){return A.eS(u.P.a(a).h(0,"layers"))},
$S:0}
A.dn.prototype={
$1(a){return A.d4("geometry-solid-volume",u.P.a(a))},
$S:2}
A.dp.prototype={
$1(a){u.P.a(a)
return A.dY(a)&&A.dV(a)===12&&A.eO(a)===32},
$S:0}
A.dq.prototype={
$1(a){return A.d4("algebra-solid-relation",u.P.a(a))},
$S:2}
A.dr.prototype={
$1(a){u.P.a(a)
return A.dY(a)&&A.dV(a)===16&&J.h(a.h(0,"width"),2*A.aa(a.h(0,"height")))&&J.h(a.h(0,"depth"),a.h(0,"height"))},
$S:0}
A.du.prototype={
$1(a){var t,s,r
A.ab(a)
t=this.a
s=!1
if(A.D(t.h(0,a))){r=t.h(0,a)
if(typeof r!=="number")return r.ad()
if(r>=1){t=t.h(0,a)
if(typeof t!=="number")return t.ae()
t=t<=5}else t=s}else t=s
return t},
$S:15}
A.dt.prototype={
$1(a){return A.D(a)},
$S:1}
A.d5.prototype={
$1(a){return!A.D(a)||!B.a.J(B.N,a)},
$S:1};(function aliases(){var t=J.a6.prototype
t.af=t.k})();(function installTearOffs(){var t=hunkHelpers._static_1
t(A,"hL","h6",4)
t(A,"hR","hN",2)
t(A,"hS","hO",2)
t(A,"i3","h3",0)
t(A,"id","hA",0)
t(A,"i7","ha",0)
t(A,"ic","hx",0)
t(A,"i6","h9",0)
t(A,"i5","h8",0)
t(A,"i8","ht",0)
t(A,"ib","hw",0)
t(A,"i9","hu",0)
t(A,"ie","hD",0)
t(A,"i4","h4",0)
t(A,"ia","hv",0)
t(A,"dU","hB",16)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.w,null)
r(A.w,[A.dz,J.bn,A.aY,J.ac,A.c,A.az,A.u,A.Y,A.b1,A.aD,A.aB,A.I,A.aA,A.c7,A.c6,A.a4,A.L,A.c4,A.aN,A.aO,A.aM,A.R,A.bP,A.cd,A.at,A.bS,A.ag,A.j,A.bi,A.bk,A.cb,A.aZ,A.bX,A.a7,A.aV,A.au,A.P,A.q])
r(J.bn,[J.bp,J.aF,J.aI,J.aH,J.aJ,J.aG,J.aq])
r(J.aI,[J.a6,J.v,A.ar,A.aT])
r(J.a6,[J.bD,J.b0,J.a5])
s(J.bo,A.aY)
s(J.c_,J.v)
r(J.aG,[J.aE,J.bq])
r(A.c,[A.a8,A.e,A.a_,A.aC])
r(A.a8,[A.ad,A.bd])
s(A.b3,A.ad)
s(A.b2,A.bd)
s(A.V,A.b2)
r(A.u,[A.bt,A.b_,A.br,A.bM,A.bH,A.bO,A.aK,A.bf,A.a3,A.bN,A.bL,A.bI,A.bj])
r(A.e,[A.X,A.ae,A.aP,A.aL])
r(A.X,[A.aQ,A.bR])
s(A.B,A.aA)
s(A.aW,A.b_)
r(A.a4,[A.bh,A.bK,A.de,A.dg,A.cE,A.cO,A.cN,A.cG,A.cP,A.cQ,A.cM,A.cS,A.cT,A.cU,A.cK,A.cL,A.cV,A.cW,A.cX,A.cJ,A.cY,A.cH,A.cI,A.cZ,A.cR,A.d0,A.d1,A.d2,A.co,A.cA,A.cw,A.cu,A.ct,A.cs,A.cl,A.cz,A.cy,A.cx,A.cB,A.cq,A.cr,A.cp,A.cj,A.ch,A.ci,A.d8,A.d9,A.da,A.db,A.d6,A.d7,A.d3,A.cv,A.cn,A.cC,A.cD,A.dj,A.dk,A.dl,A.dm,A.dn,A.dp,A.dq,A.dr,A.du,A.dt,A.d5])
r(A.bK,[A.bJ,A.ao])
r(A.L,[A.W,A.bQ])
r(A.bh,[A.c0,A.df,A.c5,A.cc,A.ck])
r(A.aT,[A.bu,A.as])
r(A.as,[A.b4,A.b6])
s(A.b5,A.b4)
s(A.aR,A.b5)
s(A.b7,A.b6)
s(A.aS,A.b7)
r(A.aR,[A.bv,A.bw])
r(A.aS,[A.bx,A.by,A.bz,A.bA,A.bB,A.aU,A.bC])
s(A.b9,A.bO)
s(A.b8,A.at)
s(A.af,A.b8)
s(A.bs,A.aK)
s(A.c1,A.bi)
r(A.bk,[A.c3,A.c2])
s(A.ca,A.cb)
r(A.a3,[A.aX,A.bm])
t(A.bd,A.j)
t(A.b4,A.j)
t(A.b5,A.I)
t(A.b6,A.j)
t(A.b7,A.I)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",k:"double",am:"num",n:"String",l:"bool",aV:"Null",f:"List",w:"Object",K:"Map",x:"JSObject"},mangledNames:{},types:["l(K<n,@>)","l(@)","P(K<n,@>)","l(l)","@(@)","~(w?,w?)","l(f<@>)","@(@,n)","@(n)","l(a)","l(f<a>)","a(a,a)","a(a)","f<q>(f<q>)","l(q)","l(n)","n(n)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti")}
A.fT(v.typeUniverse,JSON.parse('{"a5":"a6","bD":"a6","b0":"a6","ip":"ar","bp":{"l":[],"m":[]},"aF":{"m":[]},"aI":{"x":[]},"a6":{"x":[]},"v":{"f":["1"],"e":["1"],"x":[],"c":["1"]},"bo":{"aY":[]},"c_":{"v":["1"],"f":["1"],"e":["1"],"x":[],"c":["1"]},"ac":{"C":["1"]},"aG":{"k":[],"am":[]},"aE":{"k":[],"a":[],"am":[],"m":[]},"bq":{"k":[],"am":[],"m":[]},"aq":{"n":[],"m":[]},"a8":{"c":["2"]},"az":{"C":["2"]},"ad":{"a8":["1","2"],"c":["2"],"c.E":"2"},"b3":{"ad":["1","2"],"a8":["1","2"],"e":["2"],"c":["2"],"c.E":"2"},"b2":{"j":["2"],"f":["2"],"a8":["1","2"],"e":["2"],"c":["2"]},"V":{"b2":["1","2"],"j":["2"],"f":["2"],"a8":["1","2"],"e":["2"],"c":["2"],"j.E":"2","c.E":"2"},"bt":{"u":[]},"e":{"c":["1"]},"X":{"e":["1"],"c":["1"]},"Y":{"C":["1"]},"aQ":{"X":["2"],"e":["2"],"c":["2"],"c.E":"2","X.E":"2"},"a_":{"c":["1"],"c.E":"1"},"b1":{"C":["1"]},"aC":{"c":["2"],"c.E":"2"},"aD":{"C":["2"]},"aB":{"C":["1"]},"aA":{"K":["1","2"]},"B":{"aA":["1","2"],"K":["1","2"]},"aW":{"u":[]},"br":{"u":[]},"bM":{"u":[]},"a4":{"ap":[]},"bh":{"ap":[]},"bK":{"ap":[]},"bJ":{"ap":[]},"ao":{"ap":[]},"bH":{"u":[]},"W":{"L":["1","2"],"eb":["1","2"],"K":["1","2"],"L.K":"1","L.V":"2"},"ae":{"e":["1"],"c":["1"],"c.E":"1"},"aN":{"C":["1"]},"aP":{"e":["1"],"c":["1"],"c.E":"1"},"aO":{"C":["1"]},"aL":{"e":["a7<1,2>"],"c":["a7<1,2>"],"c.E":"a7<1,2>"},"aM":{"C":["a7<1,2>"]},"ar":{"x":[],"m":[]},"aT":{"x":[]},"bu":{"x":[],"m":[]},"as":{"J":["1"],"x":[]},"aR":{"j":["k"],"f":["k"],"J":["k"],"e":["k"],"x":[],"c":["k"],"I":["k"]},"aS":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"]},"bv":{"j":["k"],"f":["k"],"J":["k"],"e":["k"],"x":[],"c":["k"],"I":["k"],"m":[],"j.E":"k"},"bw":{"j":["k"],"f":["k"],"J":["k"],"e":["k"],"x":[],"c":["k"],"I":["k"],"m":[],"j.E":"k"},"bx":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"],"m":[],"j.E":"a"},"by":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"],"m":[],"j.E":"a"},"bz":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"],"m":[],"j.E":"a"},"bA":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"],"m":[],"j.E":"a"},"bB":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"],"m":[],"j.E":"a"},"aU":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"],"m":[],"j.E":"a"},"bC":{"j":["a"],"f":["a"],"J":["a"],"e":["a"],"x":[],"c":["a"],"I":["a"],"m":[],"j.E":"a"},"bO":{"u":[]},"b9":{"u":[]},"af":{"at":["1"],"ec":["1"],"e":["1"],"c":["1"]},"ag":{"C":["1"]},"L":{"K":["1","2"]},"at":{"e":["1"],"c":["1"]},"b8":{"at":["1"],"e":["1"],"c":["1"]},"bQ":{"L":["n","@"],"K":["n","@"],"L.K":"n","L.V":"@"},"bR":{"X":["n"],"e":["n"],"c":["n"],"c.E":"n","X.E":"n"},"aK":{"u":[]},"bs":{"u":[]},"k":{"am":[]},"a":{"am":[]},"f":{"e":["1"],"c":["1"]},"bf":{"u":[]},"b_":{"u":[]},"a3":{"u":[]},"aX":{"u":[]},"bm":{"u":[]},"bN":{"u":[]},"bL":{"u":[]},"bI":{"u":[]},"bj":{"u":[]},"aZ":{"u":[]},"au":{"fx":[]},"fm":{"f":["a"],"e":["a"],"c":["a"]},"fB":{"f":["a"],"e":["a"],"c":["a"]},"fA":{"f":["a"],"e":["a"],"c":["a"]},"fk":{"f":["a"],"e":["a"],"c":["a"]},"fy":{"f":["a"],"e":["a"],"c":["a"]},"fl":{"f":["a"],"e":["a"],"c":["a"]},"fz":{"f":["a"],"e":["a"],"c":["a"]},"fi":{"f":["k"],"e":["k"],"c":["k"]},"fj":{"f":["k"],"e":["k"],"c":["k"]}}'))
A.fS(v.typeUniverse,JSON.parse('{"bd":2,"as":1,"b8":1,"bi":2,"bk":2}'))
var u=(function rtii(){var t=A.be
return{R:t("B<n,@>"),Q:t("e<@>"),C:t("u"),A:t("q"),Z:t("ap"),U:t("c<@>"),J:t("v<q>"),p:t("v<f<a>>"),s:t("v<n>"),n:t("v<k>"),b:t("v<@>"),t:t("v<a>"),T:t("aF"),m:t("x"),L:t("a5"),D:t("J<@>"),X:t("f<q>"),j:t("f<@>"),M:t("f<a>"),P:t("K<n,@>"),f:t("K<@,@>"),a:t("aV"),K:t("w"),V:t("iq"),N:t("n"),k:t("m"),o:t("b0"),y:t("l"),i:t("k"),z:t("@"),S:t("a"),W:t("e9<aV>?"),B:t("x?"),Y:t("f<@>?"),O:t("w?"),v:t("n?"),g:t("bS?"),u:t("l?"),I:t("k?"),w:t("a?"),x:t("am?"),H:t("am"),E:t("~(n,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.G=J.bn.prototype
B.a=J.v.prototype
B.k=J.aE.prototype
B.H=J.aG.prototype
B.e=J.aq.prototype
B.I=J.a5.prototype
B.J=J.aI.prototype
B.l=J.bD.prototype
B.h=J.b0.prototype
B.m=new A.aB(A.be("aB<0&>"))
B.i=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.n=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.t=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.o=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.r=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.q=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.p=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.j=function(hooks) { return hooks; }

B.f=new A.c1()
B.c=t([],u.s)
B.d=new A.P(!1,B.c,"invalid-state")
B.K=new A.c2(null)
B.L=new A.c3(null)
B.N=t([10,20,30],u.t)
B.ad={}
B.b=new A.B(B.ad,[],u.R)
B.af={logic:0,math:1,science:2,data:3}
B.ac={blocks:0}
B.a0=new A.B(B.ac,[0],u.R)
B.E=new A.q("logic-balance","balanceBlocks",B.a0,A.i3(),null,B.b)
B.aj={pairs:0}
B.a_=new A.B(B.aj,[0],u.R)
B.v=new A.q("logic-remove","removeBothSides",B.a_,A.id(),null,B.b)
B.am={turns:0}
B.a2=new A.B(B.am,[0],u.R)
B.z=new A.q("logic-gears","gearRatios",B.a2,A.i7(),null,B.b)
B.S=t([B.E,B.v,B.z],u.J)
B.ai={painted:0}
B.T=t([],u.b)
B.Z=new A.B(B.ai,[B.T],u.R)
B.az=t(["fractions.part-whole"],u.s)
B.C=new A.q("math-paint","fractionPaint",B.Z,A.ic(),A.hS(),B.b)
B.ae={folds:0}
B.a1=new A.B(B.ae,[0],u.R)
B.ay=t(["fractions.equal-parts"],u.s)
B.F=new A.q("math-fold","fractionFold",B.a1,A.i6(),null,B.b)
B.aa={baskets:0}
B.M=t([0,0,0],u.t)
B.X=new A.B(B.aa,[B.M],u.R)
B.A=new A.q("math-share","distributeObjects",B.X,A.i5(),null,B.b)
B.O=t([B.C,B.F,B.A],u.J)
B.a9={angle:0,launched:1}
B.a5=new A.B(B.a9,[20,!1],u.R)
B.D=new A.q("science-launch","launchAngle",B.a5,A.i8(),null,B.b)
B.al={segments:0}
B.V=t([-1,-1,-1],u.t)
B.a6=new A.B(B.al,[B.V],u.R)
B.u=new A.q("science-motion","motionTimeline",B.a6,A.ib(),null,B.b)
B.ak={position:0}
B.a7=new A.B(B.ak,[0],u.R)
B.y=new A.q("science-lever","leverTorque",B.a7,A.i9(),null,B.b)
B.U=t([B.D,B.u,B.y],u.J)
B.ah={order:0}
B.Q=t([3,1,4,2],u.t)
B.a3=new A.B(B.ah,[B.Q],u.R)
B.w=new A.q("data-sort","sortBars",B.a3,A.ie(),null,B.b)
B.ab={bins:0}
B.R=t([-1,-1,-1,-1,-1,-1],u.t)
B.a4=new A.B(B.ab,[B.R],u.R)
B.x=new A.q("data-bins","histogramBins",B.a4,A.i4(),null,B.b)
B.ag={heights:0}
B.P=t([2,4,6],u.t)
B.Y=new A.B(B.ag,[B.P],u.R)
B.B=new A.q("data-mean","redistributeMean",B.Y,A.ia(),null,B.b)
B.W=t([B.w,B.x,B.B],u.J)
B.a8=new A.B(B.af,[B.S,B.O,B.U,B.W],A.be("B<n,f<q>>"))
B.an=A.U("ik")
B.ao=A.U("il")
B.ap=A.U("fi")
B.aq=A.U("fj")
B.ar=A.U("fk")
B.as=A.U("fl")
B.at=A.U("fm")
B.au=A.U("fy")
B.av=A.U("fz")
B.aw=A.U("fA")
B.ax=A.U("fB")})();(function staticFields(){$.c9=null
$.O=A.b([],A.be("v<w>"))
$.ef=null
$.e6=null
$.e5=null
$.eK=null
$.eI=null
$.eM=null
$.d_=null
$.dh=null
$.dR=null})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"io","eT",()=>A.dc("_$dart_dartClosure"))
t($,"im","dZ",()=>A.dc("_$dart_dartClosure_dartJSInterop"))
t($,"iC","f4",()=>A.b([new J.bo()],A.be("v<aY>")))
t($,"ir","eU",()=>A.Z(A.c8({
toString:function(){return"$receiver$"}})))
t($,"is","eV",()=>A.Z(A.c8({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"it","eW",()=>A.Z(A.c8(null)))
t($,"iu","eX",()=>A.Z(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"ix","f_",()=>A.Z(A.c8(void 0)))
t($,"iy","f0",()=>A.Z(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"iw","eZ",()=>A.Z(A.ej(null)))
t($,"iv","eY",()=>A.Z(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"iA","f2",()=>A.Z(A.ej(void 0)))
t($,"iz","f1",()=>A.Z(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"iD","f5",()=>{var s,r,q,p,o,n,m=A.b([],u.p)
for(s=u.S,r=u.t,q=1;q<=4;++q)for(p=1;p<=4;++p)for(o=1;o<=4;++o)for(n=1;n<=4;++n)if(A.fq([q,p,o,n],s).a===4)m.push(A.b([q,p,o,n],r))
return m})
t($,"iE","e_",()=>{var s=null,r="Kh\xe1m ph\xe1",q=u.t,p=u.N,o=u.z,n=A.be("v<l>"),m=u.J,l=u.s
return A.i(["geometry",A.b([A.p(B.b,s,"Di\u1ec7n t\xedch h\xecnh ch\u1eef nh\u1eadt b\u1eb1ng chi\u1ec1u d\xe0i nh\xe2n chi\u1ec1u r\u1ed9ng: 3 \xd7 2 = 6.","Th\u1eed m\u1ed9t c\u1ea1nh d\xe0i 3 \xf4 v\xe0 m\u1ed9t c\u1ea1nh d\xe0i 2 \xf4.","geometry-rectangle",A.i(["points",A.b([A.b([0,0],q),A.b([4,0],q),A.b([4,4],q),A.b([0,4],q)],u.p)],p,o),"polygonVertices","Di chuy\u1ec3n b\u1ed1n \u0111\u1ec9nh \u0111\u1ec3 t\u1ea1o h\xecnh ch\u1eef nh\u1eadt c\xf3 di\u1ec7n t\xedch 6 \xf4 vu\xf4ng.",B.c,r,"K\xe9o ra di\u1ec7n t\xedch",new A.cO()),A.p(B.b,s,"Ph\xe9p \u0111\u1ed1i x\u1ee9ng gi\u1eef nguy\xean h\xe0ng v\xe0 \u0111\u1ea3o v\u1ecb tr\xed c\u1ed9t qua tr\u1ee5c.","M\u1ed7i \xf4 \u1ea3nh c\xe1ch tr\u1ee5c m\u1ed9t kho\u1ea3ng b\u1eb1ng \xf4 g\u1ed1c.","geometry-mirror",A.i(["cells",A.b([],q)],p,o),"symmetryMirror","Ch\u1ea1m c\xe1c \xf4 b\xean ph\u1ea3i \u0111\u1ec3 ph\u1ea3n chi\u1ebfu h\xecnh xanh qua tr\u1ee5c gi\u1eefa.",B.c,r,"X\u01b0\u1edfng \u0111\u1ed1i x\u1ee9ng",new A.cP()),A.p(B.b,s,"Hai tam gi\xe1c vu\xf4ng b\u1eb1ng nhau gh\xe9p d\u1ecdc c\u1ea1nh huy\u1ec1n t\u1ea1o th\xe0nh h\xecnh vu\xf4ng.","Hai c\u1ea1nh huy\u1ec1n ph\u1ea3i tr\xf9ng nhau, hai g\xf3c vu\xf4ng n\u1eb1m \u1edf hai g\xf3c \u0111\u1ed1i di\u1ec7n.","geometry-tangram",A.i(["turns",A.b([1,1],q),"placed",A.b([!1,!1],n)],p,o),"tangramRotate","Xoay hai tam gi\xe1c, r\u1ed3i k\xe9o t\u1eebng m\u1ea3nh v\xe0o khung \u0111\u1ec3 gh\xe9p th\xe0nh h\xecnh vu\xf4ng.",B.c,r,"Hai m\u1ea3nh th\xe0nh vu\xf4ng",new A.cQ())],m),"coding",A.b([A.p(B.b,s,"M\u1ed9t thu\u1eadt to\xe1n l\xe0 chu\u1ed7i thao t\xe1c r\xf5 r\xe0ng; th\u1ee9 t\u1ef1 l\u1ec7nh quy\u1ebft \u0111\u1ecbnh \u0111\u01b0\u1eddng \u0111i.","\u0110i theo m\xe9p tr\xean r\u1ed3i r\u1ebd xu\u1ed1ng. B\u1ea1n c\xf3 th\u1ec3 x\xf3a l\u1ec7nh \u0111\u1ec3 th\u1eed l\u1ea1i.","coding-route",A.i(["commands",A.b([],l)],p,o),"robotRoute","Vu\u1ed1t tr\xean b\u1ea3n \u0111\u1ed3 ho\u1eb7c th\xeam l\u1ec7nh \u0111\u1ec3 d\u1eabn robot t\u1eeb g\xf3c tr\xe1i tr\xean t\u1edbi ng\xf4i sao. Tr\xe1nh \xf4 \u0111\xe1 \u1edf gi\u1eefa.",B.c,r,"D\u1eabn robot v\u1ec1 nh\xe0",new A.cS()),A.p(B.b,s,"L\u1eb7p [ph\u1ea3i, xu\u1ed1ng] ba l\u1ea7n t\u1ea1o \u0111\u01b0\u1eddng c\u1ea7u thang t\u1edbi \xf4 (3, 3).","Kh\u1ed1i l\u1eb7p gi\xfap d\xf9ng hai l\u1ec7nh \u0111\u1ec3 t\u1ea1o ra s\xe1u b\u01b0\u1edbc.","coding-loop",A.i(["body",A.b(["D","R"],l),"repeat",1],p,o),"loopBuilder","L\u1eafp hai l\u1ec7nh v\xe0 \u0111\u1eb7t s\u1ed1 l\u1ea7n l\u1eb7p \u0111\u1ec3 robot \u0111i \u0111\xfang c\u1ea7u thang: sang ph\u1ea3i r\u1ed3i xu\u1ed1ng, ba l\u1ea7n.",B.c,r,"C\u1ea7u thang v\xf2ng l\u1eb7p",new A.cT()),A.p(B.b,s,"M\u1ed9t m\u1ea1ng s\u1eafp x\u1ebfp d\xf9ng c\xf9ng chu\u1ed7i b\u1ed9 so s\xe1nh cho m\u1ecdi \u0111\u1ea7u v\xe0o. M\u1ed7i b\u1ed9 t\u1ef1 \u0111\u01b0a s\u1ed1 nh\u1ecf l\xean tr\xean; m\u1ea1ng n\xe0y \u0111\xe3 v\u01b0\u1ee3t qua c\u1ea3 24 ho\xe1n v\u1ecb.","M\u1ed7i b\u1ed9 so s\xe1nh ch\u1ec9 \u0111\u1ed5i ch\u1ed7 khi s\u1ed1 tr\xean l\u1edbn h\u01a1n s\u1ed1 d\u01b0\u1edbi. Th\u1eed chu\u1ed7i 1\u20132, 2\u20133, 3\u20134, r\u1ed3i x\u1eed l\xfd ba d\xe2y \u0111\u1ea7u.","coding-sort",A.i(["stages",A.b([],q),"result",A.b([],q)],p,o),"sortingNetwork","L\u1eafp t\u1ed1i \u0111a 6 b\u1ed9 so s\xe1nh gi\u1eefa c\xe1c d\xe2y k\u1ec1 nhau, r\u1ed3i ch\u1ea1y m\xe1y. M\u1ea1ng c\u1ea7n s\u1eafp \u0111\xfang c\u1ea3 24 th\u1ee9 t\u1ef1 \u0111\u1ea7u v\xe0o.",B.c,r,"Thi\u1ebft k\u1ebf m\xe1y s\u1eafp x\u1ebfp",new A.cU())],m),"circuits",A.b([A.p(B.b,s,"D\xf2ng \u0111i\u1ec7n c\u1ea7n m\u1ed9t \u0111\u01b0\u1eddng k\xedn t\u1eeb ngu\u1ed3n, qua t\u1ea3i v\xe0 tr\u1edf v\u1ec1 ngu\u1ed3n.","C\u1ea7n d\xe2y 1\u20132 v\xe0 d\xe2y 3\u20134. \u0110\u1eebng n\u1ed1i tr\u1ef1c ti\u1ebfp hai c\u1ef1c ngu\u1ed3n ho\u1eb7c n\u1ed1i t\u1eaft hai \u0111\u1ea7u \u0111\xe8n.","circuits-wire",A.i(["edges",A.b([],l)],p,o),"wireCircuit","\u0110\xe8n v\xe0 ngu\u1ed3n \u0111\xe3 g\u1eafn s\u1eb5n. K\xe9o hai d\xe2y \u0111\u1ec3 n\u1ed1i c\u1ef1c d\u01b0\u01a1ng ngu\u1ed3n t\u1edbi \u0111\u1ea7u v\xe0o \u0111\xe8n, r\u1ed3i n\u1ed1i \u0111\u1ea7u ra \u0111\xe8n v\u1ec1 c\u1ef1c \xe2m.",B.c,r,"\xc1nh s\xe1ng \u0111\u1ea7u ti\xean",new A.cV()),A.p(B.b,s,"M\u1ea1ch s\xe1ng khi (A HO\u1eb6C B) V\xc0 C. V\u1edbi A m\u1edf, B v\xe0 C \u0111\u1ec1u ph\u1ea3i \u0111\xf3ng.","A v\xe0 B m\u1eafc song song, c\u1ea3 hai c\xf9ng \u0111i qua C.","circuits-logic",A.i(["switches",A.b([!1,!1,!1],n)],p,o),"switchLogic","Nh\xe1nh A \u0111ang b\u1ea3o tr\xec: gi\u1eef A m\u1edf. B\u1eadt \u0111\xe8n b\u1eb1ng nh\xe1nh B v\xe0 c\xf4ng t\u1eafc ch\xednh C.",B.c,r,"\u0110\u01b0\u1eddng \u0111i\u1ec7n d\u1ef1 ph\xf2ng",new A.cW()),A.p(B.b,s,"Pha m\xe0u c\u1ed9ng: \u0111\u1ecf + l\u1ee5c = v\xe0ng. \u0110\xe2y l\xe0 \xe1nh s\xe1ng, kh\xe1c pha s\u01a1n.","\xc1nh s\xe1ng \u0111\u1ecf c\u1ed9ng \xe1nh s\xe1ng l\u1ee5c t\u1ea1o v\xe0ng; \xe1nh s\xe1ng lam l\xe0m m\xe0u nh\u1ea1t \u0111i.","circuits-light",A.i(["rgb",A.b([0,0,1],u.n)],p,o),"colorMixer","\u0110i\u1ec1u ch\u1ec9nh ba ch\xf9m s\xe1ng \u0111\u1ec3 t\u1ea1o m\xe0u v\xe0ng c\u1ee7a m\u1eabu.",B.c,r,"Ph\xf2ng pha \xe1nh s\xe1ng",new A.cX())],m),"probability",A.b([A.p(B.b,s,"C\xf3 2 k\u1ebft qu\u1ea3 xanh tr\xean 6 vi\xean \u0111\u1ed3ng kh\u1ea3 n\u0103ng: 2/6 = 1/3.","Trong 6 vi\xean, c\u1ea7n 2 vi\xean xanh. C\xe1c vi\xean c\xf2n l\u1ea1i m\xe0u \u0111\u1ecf.","probability-bag",A.i(["balls",A.b([],l)],p,o),"probabilityBag","Th\u1ea3 \u0111\u1ee7 6 vi\xean v\xe0o t\xfai \u0111\u1ec3 x\xe1c su\u1ea5t r\xfat m\u1ed9t vi\xean xanh l\xe0 1/3.",B.c,r,"T\xfai b\xed m\u1eadt",new A.cY()),A.p(B.b,s,"Kh\xf4ng gian m\u1eabu g\u1ed3m SS, SN, NS, NN. B\u1ed1n k\u1ebft qu\u1ea3 c\xf3 x\xe1c su\u1ea5t b\u1eb1ng nhau v\u1edbi xu c\xe2n \u0111\u1ed1i.","SN kh\xe1c NS v\xec \u0111\u1ed3ng th\u1ee9 nh\u1ea5t v\xe0 \u0111\u1ed3ng th\u1ee9 hai \u0111\u01b0\u1ee3c ph\xe2n bi\u1ec7t.","probability-space",A.i(["outcomes",A.b([],l)],p,o),"sampleSpace","Gh\xe9p t\u1eebng c\u1eb7p m\u1eb7t xu v\xe0o b\u1ea3ng \u0111\u1ec3 li\u1ec7t k\xea \u0111\u1ee7 c\xe1c k\u1ebft qu\u1ea3 khi tung hai \u0111\u1ed3ng xu c\xf3 th\u1ee9 t\u1ef1.",B.c,r,"B\u1ea3n \u0111\u1ed3 hai \u0111\u1ed3ng xu",new A.cZ()),A.p(B.b,s,"X\xe1c su\u1ea5t tr\xfang m\xe0u xanh b\u1eb1ng ph\u1ea7n g\xf3c xanh tr\xean c\u1ea3 v\xf2ng: 3 \xd7 45\xb0 / 360\xb0 = 3/8.","V\xf2ng quay \u0111\u01b0\u1ee3c chia th\xe0nh 8 cung b\u1eb1ng nhau; c\u1ea7n 3 cung xanh.","probability-spinner",A.i(["sectors",1],p,o),"probabilitySpinner","K\xe9o tay n\u1eafm \u0111\u1ec3 ph\u1ea7n m\xe0u xanh chi\u1ebfm 3/8 v\xf2ng quay.",B.c,r,"Thi\u1ebft k\u1ebf v\xf2ng quay",new A.cR())],m)],p,u.X)})
t($,"iF","f6",()=>{var s="Th\u1eed th\xe1ch",r=A.b(["fractions.part-whole"],u.s),q=u.N,p=u.z,o=u.J
return A.i(["math",A.b([A.p(B.b,A.hR(),"3/4 = 6/8. Ph\xe2n s\u1ed1 bi\u1ec3u di\u1ec5n m\u1ed9t v\u1ecb tr\xed tr\xean tr\u1ee5c s\u1ed1, kh\xf4ng ch\u1ec9 l\xe0 ph\u1ea7n t\xf4 c\u1ee7a chi\u1ebfc b\xe1nh.","Chia \u0111o\u1ea1n th\xe0nh 4 ph\u1ea7n b\u1eb1ng nhau r\u1ed3i \u0111i 3 ph\u1ea7n. Hai n\u1ea5c nh\u1ecf t\u1ea1o m\u1ed9t ph\u1ea7n t\u01b0.","math-number-line",A.i(["position",0],q,p),"fractionNumberLine","\u0110\u1eb7t \u0111i\u1ec3m t\u1ea1i 3/4 \u0111o\u1ea1n \u0111\u01b0\u1eddng t\u1eeb 0 \u0111\u1ebfn 1. M\u1ed7i n\u1ea5c l\xe0 1/8.",r,"V\u1eadn d\u1ee5ng","Ph\xe2n s\u1ed1 c\xf3 m\u1ed9t v\u1ecb tr\xed",new A.d0())],o),"logic",A.b([A.p(B.b,null,"A s\xe1ng v\xe0 B t\u1eaft l\xe0 ph\u1ea3n v\xed d\u1ee5. Khi A t\u1eaft, tr\u01b0\u1eddng h\u1ee3p \u0111\xf3 kh\xf4ng b\xe1c b\u1ecf m\u1ec7nh \u0111\u1ec1 \u201cn\u1ebfu A th\xec B\u201d.","Mu\u1ed1n b\xe1c b\u1ecf quy t\u1eafc, \u0111i\u1ec1u ki\u1ec7n \u0111\u1ea7u ph\u1ea3i x\u1ea3y ra nh\u01b0ng k\u1ebft lu\u1eadn kh\xf4ng x\u1ea3y ra.","logic-counterexample",A.i(["a",!1,"b",!1],q,p),"logicalCounterexample","C\xf3 ng\u01b0\u1eddi n\xf3i: \u201c\u0110\xe8n A s\xe1ng th\xec \u0111\xe8n B lu\xf4n s\xe1ng\u201d. B\u1eadt/t\u1eaft hai \u0111\xe8n \u0111\u1ec3 t\u1ea1o m\u1ed9t ph\u1ea3n v\xed d\u1ee5.",B.c,s,"M\u1ed9t tr\u01b0\u1eddng h\u1ee3p \u0111\u1ee7 \u0111\u1ec3 b\xe1c b\u1ecf",new A.d1())],o),"data",A.b([A.p(B.b,null,"\u0110i\u1ec3m cu\u1ed1i t\u1eeb 10 tr\u1edf l\xean l\xe0m trung b\xecnh \xedt nh\u1ea5t b\u1eb1ng 4, trong khi trung v\u1ecb v\u1eabn l\xe0 3. M\u1ed9t ngo\u1ea1i l\u1ec7 c\xf3 th\u1ec3 k\xe9o trung b\xecnh \u0111i xa.","Trung v\u1ecb l\xe0 \u0111i\u1ec3m th\u1ee9 ba sau s\u1eafp x\u1ebfp. Quan s\xe1t xem \u0111i\u1ec3m cu\u1ed1i \u1ea3nh h\u01b0\u1edfng \u0111\u1ebfn t\u1ed5ng nh\u01b0 th\u1ebf n\xe0o.","data-median-outlier",A.i(["outlier",5],q,p),"outlierExplorer","B\u1ed1n \u0111i\u1ec3m c\u1ed1 \u0111\u1ecbnh l\xe0 1, 2, 3, 4. K\xe9o \u0111i\u1ec3m cu\u1ed1i \u0111\u1ec3 trung b\xecnh l\u1edbn h\u01a1n trung v\u1ecb \xedt nh\u1ea5t 1 \u0111\u01a1n v\u1ecb.",B.c,s,"Khi m\u1ed9t \u0111i\u1ec3m \u0111i xa",new A.d2())],o)],q,u.X)})
t($,"iG","e0",()=>{var s="Th\u1eed th\xe1ch",r=null,q=u.N,p=u.z,o=u.J,n=A.b([A.dN("logic-invariant","Gi\u1eef nguy\xean s\u1ef1 c\xe2n b\u1eb1ng",5,9),A.p(A.i(["target",6],q,p),r,"C\xe2n b\u1eb1ng cho th\u1ea5y hai b\xean c\xf3 c\xf9ng kh\u1ed1i l\u01b0\u1ee3ng: h\u1ed9p n\xe0y b\u1eb1ng 6 kh\u1ed1i \u0111\u01a1n v\u1ecb.","D\xf9ng chi\u1ec1u nghi\xeang l\xe0m ph\u1ea3n h\u1ed3i; khi th\xeam qu\xe1 nhi\u1ec1u, h\xe3y l\u1ea5y b\u1edbt.","logic-hidden",A.i(["blocks",1],q,p),"balanceBlocks","H\u1ed9p m\u1edbi c\xf3 kh\u1ed1i l\u01b0\u1ee3ng kh\xe1c tr\u01b0\u1edbc. Th\xeam ho\u1eb7c l\u1ea5y kh\u1ed1i \u0111\u01a1n v\u1ecb \u0111\u1ec3 t\xecm l\xfac c\xe2n n\u1eb1m ngang.",B.c,s,"Hi\u1ec7u chu\u1ea9n h\u1ed9p b\xed m\u1eadt",new A.d8())],o),m=A.b([A.eF("math-equivalent","M\u1ed9t ph\xe2n s\u1ed1, hai c\xe1ch vi\u1ebft","Bi\u1ec3u di\u1ec5n 3/4 chi\u1ebfc b\xe1nh.",6),A.eF("math-complement","T\xecm ph\u1ea7n c\xf2n l\u1ea1i","T\xf4 sao cho ph\u1ea7n CH\u01afA t\xf4 chi\u1ebfm 3/8 chi\u1ebfc b\xe1nh.",5)],o),l=A.b([A.dM("science-distance","C\xf9ng \u0111\xedch, kh\xe1c h\xe0nh tr\xecnh","\u0110i \u0111\xfang 8 m v\xe0 k\u1ebft th\xfac b\u1eb1ng 2 gi\xe2y ngh\u1ec9.",new A.d9()),A.dM("science-return","Ch\u1eadm tr\u01b0\u1edbc, nhanh sau","\u0110i \u0111\xfang 6 m, b\u1eaft \u0111\u1ea7u \u0111i ch\u1eadm v\xe0 k\u1ebft th\xfac \u0111i nhanh.",new A.da())],o),k=u.t,j=A.b([A.dI("data-outlier","San \u0111\u1ec1u sau m\u1ed9t ngo\u1ea1i l\u1ec7",A.b([1,2,9],k),"L\xe0m ba t\xf2a cao b\u1eb1ng nhau.",A.b([4,4,4],k)),A.dI("data-distribution","C\xf9ng trung b\xecnh, kh\xe1c ph\xe2n b\u1ed1",A.b([4,4,4],k),"Gi\u1eef trung b\xecnh 4 t\u1ea7ng; t\xf2a gi\u1eefa cao 4 t\u1ea7ng, t\xf2a ph\u1ea3i g\u1ea5p ba t\xf2a tr\xe1i.",A.b([2,4,6],k))],o),i=A.b([A.eG("geometry-fence","M\u1ed9t m\u1ea3nh v\u01b0\u1eddn, hai \u0111i\u1ec1u ki\u1ec7n",8,12),A.eG("geometry-square","Khi h\xecnh vu\xf4ng xu\u1ea5t hi\u1ec7n",9,12)],o),h=A.b([A.dO("coding-shortest","Ti\u1ebft ki\u1ec7m t\u1eebng l\u1ec7nh",B.c,r),A.dO("coding-checkpoint","Gh\xe9 tr\u1ea1m tr\u01b0\u1edbc khi v\u1ec1",B.c,A.b([0,2],k))],o),g=A.b([A.eE("circuits-cyan","Tr\u1ed9n ra m\xe0u tr\u1eddi","l\u1ee5c lam",4278255615,A.b([0,1,1],k)),A.eE("circuits-white","T\u1eeb ba m\xe0u th\xe0nh tr\u1eafng","tr\u1eafng",4294967295,A.b([1,1,1],k))],o),f=A.b([A.ey("probability-fair","Thi\u1ebft k\u1ebf m\u1ed9t t\xfai c\xf4ng b\u1eb1ng",8,4,"Hai m\xe0u ph\u1ea3i c\xf3 c\u01a1 h\u1ed9i xu\u1ea5t hi\u1ec7n b\u1eb1ng nhau."),A.ey("probability-odds","C\u01a1 h\u1ed9i g\u1ea5p ba",8,6,"C\u01a1 h\u1ed9i r\xfat xanh ph\u1ea3i g\u1ea5p ba c\u01a1 h\u1ed9i r\xfat \u0111\u1ecf.")],o),e=A.b([A.dN("algebra-isolate","\u1ea8n s\u1ed1 sau nh\u1eefng kh\u1ed1i",2,8),A.dN("algebra-transfer","Thay s\u1ed1, gi\u1eef quy t\u1eafc",4,10),A.dI("algebra-model","Gi\u1ea3i b\u1eb1ng m\u1ed9t th\xe0nh ph\u1ed1",A.b([6,3,3],k),"T\xf2a gi\u1eefa g\u1ea5p \u0111\xf4i t\xf2a tr\xe1i; t\xf2a ph\u1ea3i g\u1ea5p ba t\xf2a tr\xe1i. T\xecm c\u1ea3 ba chi\u1ec1u cao.",A.b([2,4,6],k))],o),d=A.dO("optimization-debug","G\u1ee1 l\u1ed7i \u0111\u01b0\u1eddng \u0111i",A.b(["R","D"],u.s),r)
p=A.i(["stages",A.b([0,1,2],k),"result",A.b([],k)],q,p)
k=$.e_().h(0,"coding")
k.toString
return A.i(["logic",n,"math",m,"science",l,"data",j,"geometry",i,"coding",h,"circuits",g,"probability",f,"algebra",e,"optimization",A.b([d,A.p(B.b,r,"M\xe1y \u0111\u01b0\u1ee3c ki\u1ec3m tra tr\xean c\u1ea3 24 ho\xe1n v\u1ecb, kh\xf4ng ch\u1ec9 v\xed d\u1ee5 \u0111ang hi\u1ec3n th\u1ecb. Chu\u1ed7i b\u1ed9 so s\xe1nh d\xf9ng l\u1ea1i \u0111\u01b0\u1ee3c v\u1edbi m\u1ecdi \u0111\u1ea7u v\xe0o.","M\u1ed9t \u0111\u1ea7u v\xe0o ch\u1ea1y \u0111\xfang ch\u01b0a ch\u1ee9ng minh m\xe1y \u0111\xfang. T\xecm c\u1eb7p d\xe2y c\xf2n c\xf3 th\u1ec3 \u0111\u1ea3o th\u1ee9 t\u1ef1 sau m\u1ed7i l\u01b0\u1ee3t.","optimization-network",p,"sortingNetwork","M\xe1y \u0111\xe3 c\xf3 ba b\u1ed9 so s\xe1nh nh\u01b0ng ch\u01b0a s\u1eafp \u0111\xfang m\u1ecdi \u0111\u1ea7u v\xe0o. Ch\u1ec9nh ho\u1eb7c l\u1eafp th\xeam, t\u1ed1i \u0111a 6 b\u1ed9; ch\u1ea1y ki\u1ec3m tra c\u1ea3 24 ho\xe1n v\u1ecb.",B.c,s,"S\u1eeda m\xe1y, kh\xf4ng s\u1eeda \u0111\u1ea7u v\xe0o",B.a.gaz(k).w),A.dM("optimization-budget","Ng\xe2n s\xe1ch chuy\u1ec3n \u0111\u1ed9ng","\u0110i \u0111\xfang 4 m v\u1edbi ch\u1ec9 m\u1ed9t \xf4 \u0111i nhanh; hai \xf4 c\xf2n l\u1ea1i ph\u1ea3i ngh\u1ec9.",new A.db())],o)],q,u.X)})
t($,"iB","f3",()=>{var s,r,q,p,o,n="algebra",m="geography",l="optimization",k=u.N,j=u.X,i=A.fp(k,j)
for(k=A.fo(k,j),k.F(0,B.a8),k.F(0,$.e_()),k=new A.aL(k,A.o(k).i("aL<1,2>")).gp(0),j=u.A,s=u.J;k.l();){r=k.gm()
q=r.a
p=A.ee(r.b,j)
o=$.e0().h(0,q)
B.a.F(p,o==null?A.b([],s):o)
o=$.f6().h(0,q)
B.a.F(p,o==null?A.b([],s):o)
o=$.e1().h(0,q)
B.a.F(p,o==null?A.b([],s):o)
i.C(0,q,p)}k=$.e0()
s=k.h(0,n)
s.toString
j=A.ee(s,j)
s=$.e1()
q=s.h(0,n)
q.toString
B.a.F(j,q)
i.C(0,n,j)
s=s.h(0,m)
s.toString
i.C(0,m,s)
k=k.h(0,l)
k.toString
i.C(0,l,k)
return i})
t($,"iH","e1",()=>{var s="Kh\xe1m ph\xe1 3D",r="V\u1eadn d\u1ee5ng 3D",q="solidExplorer",p=u.N,o=u.z,n=u.J
return A.i(["geography",A.b([A.p(B.b,new A.dj(),"V\u0129 \u0111\u1ed9 \u0111o v\u1ecb tr\xed B\u1eafc\u2013Nam; kinh \u0111\u1ed9 \u0111o v\u1ecb tr\xed \u0110\xf4ng\u2013T\xe2y. Xoay qu\u1ea3 \u0111\u1ecba c\u1ea7u ch\u1ec9 \u0111\u1ed5i g\xf3c nh\xecn, kh\xf4ng \u0111\u1ed5i t\u1ecda \u0111\u1ed9 \u0111i\u1ec3m.","V\u0129 \u0111\u1ed9 B\u1eafc n\u1eb1m ph\xeda b\u1eafc x\xedch \u0111\u1ea1o. Kinh \u0111\u1ed9 \u0110\xf4ng \u0111\u01b0\u1ee3c \u0111o v\u1ec1 ph\xeda \u0111\xf4ng t\u1eeb kinh tuy\u1ebfn g\u1ed1c 0\xb0.","geography-globe-grid",A.i(["latitude",0,"longitude",0],p,o),"globeExplorer","\u0110\u1eb7t \u0111i\u1ec3m t\u1ea1i 15\xb0 B\u1eafc, 105\xb0 \u0110\xf4ng tr\xean qu\u1ea3 \u0111\u1ecba c\u1ea7u. Xoay \u0111\u1ec3 nh\xecn quanh, r\u1ed3i ch\u1ea1m b\u1ec1 m\u1eb7t ho\u1eb7c \u0111i\u1ec1u ch\u1ec9nh t\u1ecda \u0111\u1ed9.",B.c,s,"T\xecm \u0111\u01b0\u1eddng tr\xean qu\u1ea3 \u0111\u1ecba c\u1ea7u",new A.dk()),A.p(B.b,new A.dl(),"T\u1eeb tr\xean xu\u1ed1ng: 10, 20, 30 tri\u1ec7u n\u0103m. M\xf4 h\xecnh gi\u1ea3 \u0111\u1ecbnh c\xe1c l\u1edbp l\u1eafng \u0111\u1ecdng li\xean ti\u1ebfp, ch\u01b0a b\u1ecb bi\u1ebfn d\u1ea1ng ho\u1eb7c \u0111\u1ea3o l\u1ed9n.","Trong chu\u1ed7i tr\u1ea7m t\xedch kh\xf4ng b\u1ecb \u0111\u1ea3o l\u1ed9n, l\u1edbp b\xean d\u01b0\u1edbi h\xecnh th\xe0nh tr\u01b0\u1edbc l\u1edbp ph\u1ee7 l\xean tr\xean.","geography-rock-layers",A.i(["layers",A.b([30,10,20],u.t)],p,o),"strataExplorer","C\xe1c l\u1edbp tr\u1ea7m t\xedch ch\u01b0a b\u1ecb \u0111\u1ea3o l\u1ed9n. S\u1eafp l\u1edbp c\xf3 tu\u1ed5i 10, 20 v\xe0 30 tri\u1ec7u n\u0103m t\u1eeb tr\xean xu\u1ed1ng d\u01b0\u1edbi, theo th\u1ee9 t\u1ef1 h\xecnh th\xe0nh.",B.c,r,"\u0110\u1ecdc l\u1ecbch s\u1eed trong l\u1edbp \u0111\u1ea5t \u0111\xe1",new A.dm())],n),"geometry",A.b([A.p(B.b,new A.dn(),"Kh\u1ed1i c\xf3 c\xe1c c\u1ea1nh 2, 2, 3 th\u1ecfa V = 12 v\xe0 S = 2 \xd7 (4 + 6 + 6) = 32. \u0110\u1ed5i h\u01b0\u1edbng kh\u1ed1i kh\xf4ng \u0111\u1ed5i hai \u0111\u1ea1i l\u01b0\u1ee3ng n\xe0y.","Th\u1ec3 t\xedch l\xe0 d\xe0i \xd7 cao \xd7 s\xe2u. Th\u1eed ba k\xedch th\u01b0\u1edbc c\xf3 t\xedch b\u1eb1ng 12 r\u1ed3i so s\xe1nh t\u1ed5ng di\u1ec7n t\xedch s\xe1u m\u1eb7t.","geometry-solid-volume",A.i(["width",2,"height",2,"depth",2],p,o),q,"T\u1ea1o kh\u1ed1i h\u1ed9p c\xf3 th\u1ec3 t\xedch 12 \u0111\u01a1n v\u1ecb kh\u1ed1i v\xe0 di\u1ec7n t\xedch b\u1ec1 m\u1eb7t 32 \u0111\u01a1n v\u1ecb vu\xf4ng. Xoay kh\u1ed1i \u0111\u1ec3 quan s\xe1t c\xe1c m\u1eb7t.",B.c,s,"X\u01b0\u1edfng kh\u1ed1i kh\xf4ng gian",new A.dp())],n),"algebra",A.b([A.p(B.b,new A.dq(),"Cao = s\xe2u = 2 v\xe0 d\xe0i = 4: th\u1ec3 t\xedch l\xe0 4 \xd7 2 \xd7 2 = 16. M\xf4 h\xecnh ph\u1ea3i th\u1ecfa c\u1ea3 th\u1ec3 t\xedch l\u1eabn quan h\u1ec7 gi\u1eefa c\xe1c c\u1ea1nh.","Cho chi\u1ec1u cao v\xe0 chi\u1ec1u s\xe2u b\u1eb1ng nhau tr\u01b0\u1edbc. M\u1ed7i khi \u0111\u1ed5i chi\u1ec1u cao, chi\u1ec1u d\xe0i c\u1ea7n thay \u0111\u1ed5i th\u1ebf n\xe0o?","algebra-solid-relation",A.i(["width",2,"height",2,"depth",2],p,o),q,"D\u1ef1ng kh\u1ed1i h\u1ed9p c\xf3 th\u1ec3 t\xedch 16 \u0111\u01a1n v\u1ecb kh\u1ed1i. Chi\u1ec1u d\xe0i g\u1ea5p \u0111\xf4i chi\u1ec1u cao; chi\u1ec1u s\xe2u b\u1eb1ng chi\u1ec1u cao.",B.c,r,"M\u1ed9t kh\u1ed1i, ba quan h\u1ec7",new A.dr())],n)],p,u.X)})})();(function nativeSupport(){!function(){var t=function(a){var n={}
n[a]=1
return Object.keys(hunkHelpers.convertToFastObject(n))[0]}
v.getIsolateTag=function(a){return t("___dart_"+a+v.isolateTag)}
var s="___dart_isolate_tags_"
var r=Object[s]||(Object[s]=Object.create(null))
var q="_ZxYxX"
for(var p=0;;p++){var o=t(q+"_"+p+"_")
if(!(o in r)){r[o]=1
v.isolateTag=o
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.ar,SharedArrayBuffer:A.ar,ArrayBufferView:A.aT,DataView:A.bu,Float32Array:A.bv,Float64Array:A.bw,Int16Array:A.bx,Int32Array:A.by,Int8Array:A.bz,Uint16Array:A.bA,Uint32Array:A.bB,Uint8ClampedArray:A.aU,CanvasPixelArray:A.aU,Uint8Array:A.bC})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.as.$nativeSuperclassTag="ArrayBufferView"
A.b4.$nativeSuperclassTag="ArrayBufferView"
A.b5.$nativeSuperclassTag="ArrayBufferView"
A.aR.$nativeSuperclassTag="ArrayBufferView"
A.b6.$nativeSuperclassTag="ArrayBufferView"
A.b7.$nativeSuperclassTag="ArrayBufferView"
A.aS.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
Function.prototype.$1$0=function(){return this()}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.i1
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()