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
if(a[b]!==t){A.j9(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.a(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.em(b)
return new t(c,this)}:function(){if(t===null)t=A.em(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.em(a).prototype
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
eq(a,b,c,d){return{i:a,p:b,e:c,x:d}},
en(a){var t,s,r,q,p,o="_$dart_js",n=a[v.dispatchPropertyName]
if(n==null)if($.eo==null){A.iN()
n=a[v.dispatchPropertyName]}if(n!=null){t=n.p
if(!1===t)return n.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return n.i
if(n.e===s)throw A.e(A.eV("Return interceptor for "+A.x(t(a,n))))}r=a.constructor
if(r==null)q=null
else{p=$.cs
if(p==null)p=$.cs=A.dF(o)
q=r[p]}if(q!=null)return q
q=A.iS(a)
if(q!=null)return q
if(typeof a=="function")return B.I
t=Object.getPrototypeOf(a)
if(t==null)return B.l
if(t===Object.prototype)return B.l
if(typeof r=="function"){p=$.cs
if(p==null)p=$.cs=A.dF(o)
Object.defineProperty(r,p,{value:B.h,enumerable:false,writable:true,configurable:true})
return B.h}return B.h},
av(a,b){return A.a(new Array(a),b.j("A<0>"))},
eK(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
ha(a,b){var t,s
for(t=a.length;b<t;){s=a.charCodeAt(b)
if(s!==32&&s!==13&&!J.eK(s))break;++b}return b},
hb(a,b){var t,s,r
for(t=a.length;b>0;b=s){s=b-1
if(!(s<t))return A.y(a,s)
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.eK(r))break}return b},
Y(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.aO.prototype
return J.bB.prototype}if(typeof a=="string")return J.ai.prototype
if(a==null)return J.aP.prototype
if(typeof a=="boolean")return J.bA.prototype
if(Array.isArray(a))return J.A.prototype
if(typeof a!="object"){if(typeof a=="function")return J.ab.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.w)return a
return J.en(a)},
o(a){if(typeof a=="string")return J.ai.prototype
if(a==null)return a
if(Array.isArray(a))return J.A.prototype
if(typeof a!="object"){if(typeof a=="function")return J.ab.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.w)return a
return J.en(a)},
Z(a){if(a==null)return a
if(Array.isArray(a))return J.A.prototype
if(typeof a!="object"){if(typeof a=="function")return J.ab.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.w)return a
return J.en(a)},
iJ(a){if(typeof a=="string")return J.ai.prototype
if(a==null)return a
if(!(a instanceof A.w))return J.aB.prototype
return a},
f(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.Y(a).B(a,b)},
v(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.iQ(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.o(a).h(a,b)},
fQ(a,b){return J.iJ(a).af(a,b)},
fR(a,b){return J.Z(a).J(a,b)},
cc(a,b){return J.Z(a).S(a,b)},
fS(a,b){return J.o(a).v(a,b)},
eC(a,b){return J.Z(a).C(a,b)},
fT(a,b){return J.Z(a).t(a,b)},
cd(a){return J.Y(a).gD(a)},
fU(a){return J.o(a).gu(a)},
fV(a){return J.Z(a).gL(a)},
a8(a){return J.Z(a).gn(a)},
V(a){return J.o(a).gi(a)},
fW(a){return J.Y(a).gA(a)},
dZ(a){return J.Z(a).H(a)},
aH(a){return J.Y(a).k(a)},
by:function by(){},
bA:function bA(){},
aP:function aP(){},
aT:function aT(){},
ac:function ac(){},
bO:function bO(){},
aB:function aB(){},
ab:function ab(){},
aS:function aS(){},
aU:function aU(){},
A:function A(a){this.$ti=a},
bz:function bz(){},
cf:function cf(a){this.$ti=a},
ag:function ag(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aQ:function aQ(){},
aO:function aO(){},
bB:function bB(){},
ai:function ai(){}},A={e2:function e2(){},
fZ(a,b,c){if(u.Q.b(a))return new A.be(a,b.j("@<0>").G(c).j("be<1,2>"))
return new A.ah(a,b.j("@<0>").G(c).j("ah<1,2>"))},
ep(a){var t,s
for(t=$.S.length,s=0;s<t;++s)if(a===$.S[s])return!0
return!1},
aN(){return new A.bT("No element")},
a6:function a6(){},
aI:function aI(a,b){this.a=a
this.$ti=b},
ah:function ah(a,b){this.a=a
this.$ti=b},
be:function be(a,b){this.a=a
this.$ti=b},
bd:function bd(){},
a0:function a0(a,b){this.a=a
this.$ti=b},
bE:function bE(a){this.a=a},
h:function h(){},
a2:function a2(){},
a3:function a3(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
b0:function b0(a,b,c){this.a=a
this.b=b
this.$ti=c},
a5:function a5(a,b,c){this.a=a
this.b=b
this.$ti=c},
bc:function bc(a,b,c){this.a=a
this.b=b
this.$ti=c},
aL:function aL(a,b,c){this.a=a
this.b=b
this.$ti=c},
aM:function aM(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aK:function aK(a){this.$ti=a},
K:function K(){},
bo:function bo(){},
fv(a){var t=A.fu(a)
if(t!=null)return t
return"minified:"+a},
iQ(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.D.b(a)},
x(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.aH(a)
return t},
bP(a){var t,s=$.eP
if(s==null)s=$.eP=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
bQ(a){var t,s,r,q
if(a instanceof A.w)return A.R(A.X(a),null)
t=J.Y(a)
if(t===B.G||t===B.J||u.o.b(a)){s=B.i(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.R(A.X(a),null)},
hh(a){var t,s,r
if(typeof a=="number"||A.eg(a))return J.aH(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.aa)return a.k(0)
t=$.fK()
for(s=0;s<1;++s){r=t[s].aK(a)
if(r!=null)return r}return"Instance of '"+A.bQ(a)+"'"},
H(a){var t
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.k.ae(t,10)|55296)>>>0,t&1023|56320)}throw A.e(A.bR(a,0,1114111,null,null))},
dG(a){throw A.e(A.iA(a))},
y(a,b){if(a==null)J.V(a)
throw A.e(A.d2(a,b))},
d2(a,b){var t,s="index"
if(!A.u(b))return new A.a9(!0,b,s,null)
t=J.V(a)
if(b<0||b>=t)return A.e0(b,t,a,s)
return new A.b7(null,null,!0,b,s,"Value not in range")},
iA(a){return new A.a9(!0,a,null,null)},
e(a){return A.I(a,new Error())},
I(a,b){var t
if(a==null)a=new A.bb()
b.dartException=a
t=A.ja
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
ja(){return J.aH(this.dartException)},
dW(a,b){throw A.I(a,b==null?new Error():b)},
ev(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.dW(A.hW(a,b,c),t)},
hW(a,b,c){var t,s,r,q,p,o,n,m,l
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
return new A.bZ("'"+t+"': Cannot "+p+" "+m+l+o)},
eu(a){throw A.e(A.F(a))},
a4(a){var t,s,r,q,p,o
a=A.fr(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.a([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.cq(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
cr(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
eU(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
e3(a,b){var t=b==null,s=t?null:b.method
return new A.bC(a,s,t?null:b.receiver)},
fw(a){if(a==null)return new A.co(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.as(a,a.dartException)
return A.iz(a)},
as(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
iz(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.k.ae(s,16)&8191)===10)switch(r){case 438:return A.as(a,A.e3(A.x(t)+" (Error "+r+")",null))
case 445:case 5007:A.x(t)
return A.as(a,new A.b6())}}if(a instanceof TypeError){q=$.fz()
p=$.fA()
o=$.fB()
n=$.fC()
m=$.fF()
l=$.fG()
k=$.fE()
$.fD()
j=$.fI()
i=$.fH()
h=q.F(t)
if(h!=null)return A.as(a,A.e3(A.a7(t),h))
else{h=p.F(t)
if(h!=null){h.method="call"
return A.as(a,A.e3(A.a7(t),h))}else if(o.F(t)!=null||n.F(t)!=null||m.F(t)!=null||l.F(t)!=null||k.F(t)!=null||n.F(t)!=null||j.F(t)!=null||i.F(t)!=null){A.a7(t)
return A.as(a,new A.b6())}}return A.as(a,new A.bY(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.ba()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.as(a,new A.a9(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.ba()
return a},
j6(a){if(a==null)return J.cd(a)
if(typeof a=="object")return A.bP(a)
return J.cd(a)},
iF(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.q(0,a[t],a[s])}return b},
iG(a,b){var t,s=a.length
for(t=0;t<s;++t)b.p(0,a[t])
return b},
h3(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.bU().constructor.prototype):Object.create(new A.at(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.eH(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.h_(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.eH(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
h_(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.e("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.fX)}throw A.e("Error in functionType of tearoff")},
h0(a,b,c,d){var t=A.eG
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
eH(a,b,c,d){if(c)return A.h2(a,b,d)
return A.h0(b.length,d,a,b)},
h1(a,b,c,d){var t=A.eG,s=A.fY
switch(b?-1:a){case 0:throw A.e(new A.bS("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
h2(a,b,c){var t,s
if($.eE==null)$.eE=A.eD("interceptor")
if($.eF==null)$.eF=A.eD("receiver")
t=b.length
s=A.h1(t,c,a,b)
return s},
em(a){return A.h3(a)},
fX(a,b){return A.cy(v.typeUniverse,A.X(a.a),b)},
eG(a){return a.a},
fY(a){return a.b},
eD(a){var t,s,r,q=new A.at("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.e(A.e_("Field name "+a+" not found."))},
dF(a){return v.getIsolateTag(a)},
iS(a){var t,s,r,q,p,o=A.a7($.fn.$1(a)),n=$.dn[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dK[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.f6($.fj.$2(a,o))
if(r!=null){n=$.dn[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dK[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.dL(t)
$.dn[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.dK[o]=t
return t}if(q==="-"){p=A.dL(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.fp(a,t)
if(q==="*")throw A.e(A.eV(o))
if(v.leafTags[o]===true){p=A.dL(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.fp(a,t)},
fp(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.eq(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
dL(a){return J.eq(a,!1,null,!!a.$iN)},
iU(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.dL(t)
else return J.eq(t,c,null,null)},
iN(){if(!0===$.eo)return
$.eo=!0
A.iO()},
iO(){var t,s,r,q,p,o,n,m
$.dn=Object.create(null)
$.dK=Object.create(null)
A.iM()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.fq.$1(p)
if(o!=null){n=A.iU(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
iM(){var t,s,r,q,p,o,n=B.n()
n=A.aF(B.o,A.aF(B.p,A.aF(B.j,A.aF(B.j,A.aF(B.q,A.aF(B.r,A.aF(B.t(B.i),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.fn=new A.dH(q)
$.fj=new A.dI(p)
$.fq=new A.dJ(o)},
aF(a,b){return a(b)||b},
iC(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
eL(a,b,c,d,e,f){var t=b?"m":"",s=c?"":"i",r=d?"u":"",q=e?"s":"",p=function(g,h){try{return new RegExp(g,h)}catch(o){return o}}(a,t+s+r+q+f)
if(p instanceof RegExp)return p
throw A.e(A.eI("Illegal RegExp pattern ("+String(p)+")",a))},
fl(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
fr(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
et(a,b,c){var t
if(typeof b=="string")return A.j8(a,b,c)
if(b instanceof A.aR){t=b.gac()
t.lastIndex=0
return a.replace(t,A.fl(c))}return A.j7(a,b,c)},
j7(a,b,c){var t,s,r,q
for(t=J.fQ(b,a),t=t.gn(t),s=0,r="";t.l();){q=t.gm()
r=r+a.substring(s,q.ga6())+c
s=q.ga1()}t=r+a.substring(s)
return t.charCodeAt(0)==0?t:t},
j8(a,b,c){var t,s,r
if(b===""){if(a==="")return c
t=a.length
for(s=c,r=0;r<t;++r)s=s+a[r]+c
return s.charCodeAt(0)==0?s:s}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.fr(b),"g"),A.fl(c))},
aJ:function aJ(){},
G:function G(a,b,c){this.a=a
this.b=b
this.$ti=c},
b9:function b9(){},
cq:function cq(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
b6:function b6(){},
bC:function bC(a,b,c){this.a=a
this.b=b
this.c=c},
bY:function bY(a){this.a=a},
co:function co(a){this.a=a},
aa:function aa(){},
bs:function bs(){},
bW:function bW(){},
bU:function bU(){},
at:function at(a,b){this.a=a
this.b=b},
bS:function bS(a){this.a=a},
a1:function a1(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cg:function cg(a){this.a=a},
ck:function ck(a,b){this.a=a
this.b=b
this.c=null},
aj:function aj(a,b){this.a=a
this.$ti=b},
aY:function aY(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
b_:function b_(a,b){this.a=a
this.$ti=b},
aZ:function aZ(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aW:function aW(a,b){this.a=a
this.$ti=b},
aX:function aX(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
dH:function dH(a){this.a=a},
dI:function dI(a){this.a=a},
dJ:function dJ(a){this.a=a},
aR:function aR(a,b){var _=this
_.a=a
_.b=b
_.e=_.c=null},
c6:function c6(a){this.b=a},
c_:function c_(a,b,c){this.a=a
this.b=b
this.c=c},
c0:function c0(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
bV:function bV(a,b){this.a=a
this.c=b},
c7:function c7(a,b,c){this.a=a
this.b=b
this.c=c},
c8:function c8(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
an(a,b,c){if(a>>>0!==a||a>=c)throw A.e(A.d2(b,a))},
ax:function ax(){},
b3:function b3(){},
bF:function bF(){},
ay:function ay(){},
b1:function b1(){},
b2:function b2(){},
bG:function bG(){},
bH:function bH(){},
bI:function bI(){},
bJ:function bJ(){},
bK:function bK(){},
bL:function bL(){},
bM:function bM(){},
b4:function b4(){},
bN:function bN(){},
bf:function bf(){},
bg:function bg(){},
bh:function bh(){},
bi:function bi(){},
e7(a,b){var t=b.c
return t==null?b.c=A.bm(a,"eJ",[b.x]):t},
eS(a){var t=a.w
if(t===6||t===7)return A.eS(a.x)
return t===11||t===12},
hk(a){return a.as},
bp(a){return A.cx(v.typeUniverse,a,!1)},
ao(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.ao(a0,t,a2,a3)
if(s===t)return a1
return A.f1(a0,s,!0)
case 7:t=a1.x
s=A.ao(a0,t,a2,a3)
if(s===t)return a1
return A.f0(a0,s,!0)
case 8:r=a1.y
q=A.aE(a0,r,a2,a3)
if(q===r)return a1
return A.bm(a0,a1.x,q)
case 9:p=a1.x
o=A.ao(a0,p,a2,a3)
n=a1.y
m=A.aE(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.e9(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.aE(a0,k,a2,a3)
if(j===k)return a1
return A.f2(a0,l,j)
case 11:i=a1.x
h=A.ao(a0,i,a2,a3)
g=a1.y
f=A.iw(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.f_(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.aE(a0,e,a2,a3)
p=a1.x
o=A.ao(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.ea(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.e(A.br("Attempted to substitute unexpected RTI kind "+a))}},
aE(a,b,c,d){var t,s,r,q,p=b.length,o=A.cz(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.ao(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
ix(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.cz(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.ao(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
iw(a,b,c,d){var t,s=b.a,r=A.aE(a,s,c,d),q=b.b,p=A.aE(a,q,c,d),o=b.c,n=A.ix(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.c2()
t.a=r
t.b=p
t.c=n
return t},
a(a,b){a[v.arrayRti]=b
return a},
fk(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.iL(t)
return a.$S()}return null},
iP(a,b){var t
if(A.eS(b))if(a instanceof A.aa){t=A.fk(a)
if(t!=null)return t}return A.X(a)},
X(a){if(a instanceof A.w)return A.q(a)
if(Array.isArray(a))return A.Q(a)
return A.ee(J.Y(a))},
Q(a){var t=a[v.arrayRti],s=u.b
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
q(a){var t=a.$ti
return t!=null?t:A.ee(a)},
ee(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.i5(a,t)},
i5(a,b){var t=a instanceof A.aa?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.hJ(v.typeUniverse,t.name)
b.$ccache=s
return s},
iL(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.cx(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
iK(a){return A.ap(A.q(a))},
iv(a){var t=a instanceof A.aa?A.fk(a):null
if(t!=null)return t
if(u.k.b(a))return J.fW(a).a
if(Array.isArray(a))return A.Q(a)
return A.X(a)},
ap(a){var t=a.r
return t==null?a.r=new A.cw(a):t},
a_(a){return A.ap(A.cx(v.typeUniverse,a,!1))},
i4(a){var t=this
t.b=A.iu(t)
return t.b(a)},
iu(a){var t,s,r,q,p
if(a===u.K)return A.ib
if(A.aq(a))return A.ig
t=a.w
if(t===6)return A.i2
if(t===1)return A.fc
if(t===7)return A.i6
s=A.is(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.aq)){a.f="$i"+r
if(r==="i")return A.i9
if(a===u.m)return A.i8
return A.ie}}else if(t===10){q=A.iC(a.x,a.y)
p=q==null?A.fc:q
return p==null?A.ec(p):p}return A.i0},
is(a){if(a.w===8){if(a===u.S)return A.u
if(a===u.i||a===u.H)return A.ia
if(a===u.N)return A.id
if(a===u.y)return A.eg}return null},
i3(a){var t=this,s=A.i_
if(A.aq(t))s=A.hR
else if(t===u.K)s=A.ec
else if(A.aG(t)){s=A.i1
if(t===u.w)s=A.hO
else if(t===u.v)s=A.f6
else if(t===u.u)s=A.hL
else if(t===u.x)s=A.eb
else if(t===u.I)s=A.hN
else if(t===u.B)s=A.hQ}else if(t===u.S)s=A.D
else if(t===u.N)s=A.a7
else if(t===u.y)s=A.aD
else if(t===u.H)s=A.af
else if(t===u.i)s=A.hM
else if(t===u.m)s=A.hP
t.a=s
return t.a(a)},
i0(a){var t=this
if(a==null)return A.aG(t)
return A.iR(v.typeUniverse,A.iP(a,t),t)},
i2(a){if(a==null)return!0
return this.x.b(a)},
ie(a){var t,s=this
if(a==null)return A.aG(s)
t=s.f
if(a instanceof A.w)return!!a[t]
return!!J.Y(a)[t]},
i9(a){var t,s=this
if(a==null)return A.aG(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.w)return!!a[t]
return!!J.Y(a)[t]},
i8(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.w)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
fb(a){if(typeof a=="object"){if(a instanceof A.w)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
i_(a){var t=this
if(a==null){if(A.aG(t))return a}else if(t.b(a))return a
throw A.I(A.f8(a,t),new Error())},
i1(a){var t=this
if(a==null||t.b(a))return a
throw A.I(A.f8(a,t),new Error())},
f8(a,b){return new A.bk("TypeError: "+A.eW(a,A.R(b,null)))},
eW(a,b){return A.bw(a)+": type '"+A.R(A.iv(a),null)+"' is not a subtype of type '"+b+"'"},
T(a,b){return new A.bk("TypeError: "+A.eW(a,b))},
i6(a){var t=this
return t.x.b(a)||A.e7(v.typeUniverse,t).b(a)},
ib(a){return a!=null},
ec(a){if(a!=null)return a
throw A.I(A.T(a,"Object"),new Error())},
ig(a){return!0},
hR(a){return a},
fc(a){return!1},
eg(a){return!0===a||!1===a},
aD(a){if(!0===a)return!0
if(!1===a)return!1
throw A.I(A.T(a,"bool"),new Error())},
hL(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.I(A.T(a,"bool?"),new Error())},
hM(a){if(typeof a=="number")return a
throw A.I(A.T(a,"double"),new Error())},
hN(a){if(typeof a=="number")return a
if(a==null)return a
throw A.I(A.T(a,"double?"),new Error())},
u(a){return typeof a=="number"&&Math.floor(a)===a},
D(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.I(A.T(a,"int"),new Error())},
hO(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.I(A.T(a,"int?"),new Error())},
ia(a){return typeof a=="number"},
af(a){if(typeof a=="number")return a
throw A.I(A.T(a,"num"),new Error())},
eb(a){if(typeof a=="number")return a
if(a==null)return a
throw A.I(A.T(a,"num?"),new Error())},
id(a){return typeof a=="string"},
a7(a){if(typeof a=="string")return a
throw A.I(A.T(a,"String"),new Error())},
f6(a){if(typeof a=="string")return a
if(a==null)return a
throw A.I(A.T(a,"String?"),new Error())},
hP(a){if(A.fb(a))return a
throw A.I(A.T(a,"JSObject"),new Error())},
hQ(a){if(a==null)return a
if(A.fb(a))return a
throw A.I(A.T(a,"JSObject?"),new Error())},
fh(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.R(a[r],b)
return t},
ip(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.fh(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.R(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
f9(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.a([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.a.p(a3,"T"+(s+r))
for(q=u.O,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.y(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.R(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.R(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.R(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.R(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.R(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
R(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.R(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.R(a.x,b)+">"
if(m===8){q=A.iy(a.x)
p=a.y
return p.length>0?q+("<"+A.fh(p,b)+">"):q}if(m===10)return A.ip(a,b)
if(m===11)return A.f9(a,b,null)
if(m===12)return A.f9(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.y(b,o)
return b[o]}return"?"},
iy(a){var t=A.fu(a)
if(t!=null)return t
return"minified:"+a},
hK(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
hJ(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.cx(a,b,!1)
else if(typeof n=="number"){t=n
s=A.bn(a,5,"#")
r=A.cz(t)
for(q=0;q<t;++q)r[q]=s
p=A.bm(a,b,r)
o[b]=p
return p}else return n},
hH(a,b){return A.f4(a.tR,b)},
hG(a,b){return A.f4(a.eT,b)},
cx(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.f3(a,null,b,!1)
s.set(b,t)
return t},
cy(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.f3(a,b,c,!0)
r.set(c,s)
return s},
hI(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.e9(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
f3(a,b,c,d){return A.hz(A.ht(a,b,c,d))},
ae(a,b){b.a=A.i3
b.b=A.i4
return b},
bn(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.W(null,null)
t.w=b
t.as=c
s=A.ae(a,t)
a.eC.set(c,s)
return s},
f1(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.hE(a,b,s,c)
a.eC.set(s,t)
return t},
hE(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.aq(b))if(!(b===u.a||b===u.T))if(t!==6)s=t===7&&A.aG(b.x)
if(s)return b
else if(t===1)return u.a}r=new A.W(null,null)
r.w=6
r.x=b
r.as=c
return A.ae(a,r)},
f0(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.hC(a,b,s,c)
a.eC.set(s,t)
return t},
hC(a,b,c,d){var t,s
if(d){t=b.w
if(A.aq(b)||b===u.K)return b
else if(t===1)return A.bm(a,"eJ",[b])
else if(b===u.a||b===u.T)return u.W}s=new A.W(null,null)
s.w=7
s.x=b
s.as=c
return A.ae(a,s)},
hF(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.W(null,null)
t.w=13
t.x=b
t.as=r
s=A.ae(a,t)
a.eC.set(r,s)
return s},
bl(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
hB(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
bm(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.bl(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.W(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.ae(a,s)
a.eC.set(q,r)
return r},
e9(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.bl(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.W(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.ae(a,p)
a.eC.set(r,o)
return o},
f2(a,b,c){var t,s,r="+"+(b+"("+A.bl(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.W(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.ae(a,t)
a.eC.set(r,s)
return s},
f_(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.bl(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.bl(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.hB(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.W(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.ae(a,q)
a.eC.set(s,p)
return p},
ea(a,b,c,d){var t,s=b.as+("<"+A.bl(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.hD(a,b,c,s,d)
a.eC.set(s,t)
return t},
hD(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.cz(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.ao(a,b,s,0)
n=A.aE(a,c,s,0)
return A.ea(a,o,n,c!==n)}}m=new A.W(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.ae(a,m)},
ht(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
hz(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.hv(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.eY(a,s,m,l,!1)
else if(r===46)s=A.eY(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.am(a.u,a.e,l.pop()))
break
case 94:l.push(A.hF(a.u,l.pop()))
break
case 35:l.push(A.bn(a.u,5,"#"))
break
case 64:l.push(A.bn(a.u,2,"@"))
break
case 126:l.push(A.bn(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.hx(a,l)
break
case 38:A.hw(a,l)
break
case 63:q=a.u
l.push(A.f1(q,A.am(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.f0(q,A.am(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.hu(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.eZ(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.hA(a.u,a.e,p)
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
return A.am(a.u,a.e,n)},
hv(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
eY(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.hK(t,p.x)[q]
if(o==null)A.dW('No "'+q+'" in "'+A.hk(p)+'"')
d.push(A.cy(t,p,o))}else d.push(q)
return n},
hx(a,b){var t,s=a.u,r=A.eX(a,b),q=b.pop()
if(typeof q=="string")b.push(A.bm(s,q,r))
else{t=A.am(s,a.e,q)
switch(t.w){case 11:b.push(A.ea(s,t,r,a.n))
break
default:b.push(A.e9(s,t,r))
break}}},
hu(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.eX(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.am(q,a.e,p)
r=new A.c2()
r.a=t
r.b=o
r.c=n
b.push(A.f_(q,s,r))
return
case-4:b.push(A.f2(q,b.pop(),t))
return
default:throw A.e(A.br("Unexpected state under `()`: "+A.x(p)))}},
hw(a,b){var t=b.pop()
if(0===t){b.push(A.bn(a.u,1,"0&"))
return}if(1===t){b.push(A.bn(a.u,4,"1&"))
return}throw A.e(A.br("Unexpected extended operation "+A.x(t)))},
eX(a,b){var t=b.splice(a.p)
A.eZ(a.u,a.e,t)
a.p=b.pop()
return t},
am(a,b,c){if(typeof c=="string")return A.bm(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.hy(a,b,c)}else return c},
eZ(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.am(a,b,c[t])},
hA(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.am(a,b,c[t])},
hy(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.e(A.br("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.e(A.br("Bad index "+c+" for "+b.k(0)))},
iR(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.E(a,b,null,c,null)
s.set(c,t)}return t},
E(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.aq(d))return!0
t=b.w
if(t===4)return!0
if(A.aq(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.E(a,c[b.x],c,d,e))return!0
r=d.w
q=u.a
if(b===q||b===u.T){if(r===7)return A.E(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.E(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.E(a,b.x,c,d,e))return!1
return A.E(a,A.e7(a,b),c,d,e)}if(t===6)return A.E(a,q,c,d,e)&&A.E(a,b.x,c,d,e)
if(r===7){if(A.E(a,b,c,d.x,e))return!0
return A.E(a,b,c,A.e7(a,d),e)}if(r===6)return A.E(a,b,c,q,e)||A.E(a,b,c,d.x,e)
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
if(!A.E(a,k,c,j,e)||!A.E(a,j,e,k,c))return!1}return A.fa(a,b.x,c,d.x,e)}if(r===11){if(b===u.L)return!0
if(q)return!1
return A.fa(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.i7(a,b,c,d,e)}if(p&&r===10)return A.ic(a,b,c,d,e)
return!1},
fa(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.E(a2,a3.x,a4,a5.x,a6))return!1
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
if(!A.E(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.E(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.E(a2,l[i],a6,h,a4))return!1}g=t.c
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
if(!A.E(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
i7(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.cy(a,b,s[p])
return A.f5(a,q,null,c,d.y,e)}return A.f5(a,b.y,null,c,d.y,e)},
f5(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.E(a,b[t],d,e[t],f))return!1
return!0},
ic(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.E(a,s[t],c,r[t],e))return!1
return!0},
aG(a){var t=a.w,s=!0
if(!(a===u.a||a===u.T))if(!A.aq(a))if(t!==6)s=t===7&&A.aG(a.x)
return s},
aq(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.O},
f4(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
cz(a){return a>0?new Array(a):v.typeUniverse.sEA},
W:function W(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
c2:function c2(){this.c=this.b=this.a=null},
cw:function cw(a){this.a=a},
c1:function c1(){},
bk:function bk(a){this.a=a},
hc(a,b){return new A.a1(a.j("@<0>").G(b).j("a1<1,2>"))},
d(a,b,c){return b.j("@<0>").G(c).j("eN<1,2>").a(A.iF(a,new A.a1(b.j("@<0>").G(c).j("a1<1,2>"))))},
cl(a,b){return new A.a1(a.j("@<0>").G(b).j("a1<1,2>"))},
e4(a){return new A.ak(a.j("ak<0>"))},
hd(a,b){return b.j("eO<0>").a(A.iG(a,new A.ak(b.j("ak<0>"))))},
e8(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
hs(a,b,c){var t=new A.al(a,b,c.j("al<0>"))
t.c=a.e
return t},
he(a,b){var t,s,r=A.e4(b)
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.eu)(a),++s)r.p(0,b.a(a[s]))
return r},
e6(a){var t,s
if(A.ep(a))return"{...}"
t=new A.aA("")
try{s={}
B.a.p($.S,a)
t.a+="{"
s.a=!0
a.K(0,new A.cn(s,t))
t.a+="}"}finally{if(0>=$.S.length)return A.y($.S,-1)
$.S.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
ak:function ak(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
c5:function c5(a){this.a=a
this.b=null},
al:function al(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
j:function j(){},
P:function P(){},
cn:function cn(a,b){this.a=a
this.b=b},
az:function az(){},
bj:function bj(){},
io(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.fw(s)
r=A.eI(String(t),null)
throw A.e(r)}r=A.cH(q)
return r},
cH(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.c3(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.cH(a[t])
return a},
eM(a,b,c){return new A.aV(a,b)},
hV(a){return a.aP()},
hq(a,b){return new A.ct(a,[],A.iB())},
hr(a,b,c){var t,s=new A.aA(""),r=A.hq(s,b)
r.U(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
c3:function c3(a,b){this.a=a
this.b=b
this.c=null},
c4:function c4(a){this.a=a},
bt:function bt(){},
bv:function bv(){},
aV:function aV(a,b){this.a=a
this.b=b},
bD:function bD(a,b){this.a=a
this.b=b},
ch:function ch(){},
cj:function cj(a){this.b=a},
ci:function ci(a){this.a=a},
cu:function cu(){},
cv:function cv(a,b){this.a=a
this.b=b},
ct:function ct(a,b,c){this.c=a
this.a=b
this.b=c},
cm(a,b,c){var t,s,r
if(a>4294967295)A.dW(A.bR(a,0,4294967295,"length",null))
t=A.a(new Array(a),c.j("A<0>"))
t.$flags=1
s=t
if(a!==0&&b!=null)for(t=s.length,r=0;r<t;++r)s[r]=b
return s},
hg(a,b){var t,s=A.a([],b.j("A<0>"))
for(t=J.a8(a);t.l();)B.a.p(s,b.a(t.gm()))
return s},
e5(a,b){var t=A.hf(a,b)
return t},
hf(a,b){var t,s
if(Array.isArray(a))return A.a(a.slice(0),b.j("A<0>"))
t=A.a([],b.j("A<0>"))
for(s=J.a8(a);s.l();)B.a.p(t,s.gm())
return t},
eR(a){return new A.aR(a,A.eL(a,!1,!0,!1,!1,""))},
eT(a,b,c){var t=J.a8(b)
if(!t.l())return a
if(c.length===0){do a+=A.x(t.gm())
while(t.l())}else{a+=A.x(t.gm())
while(t.l())a=a+c+A.x(t.gm())}return a},
bw(a){if(typeof a=="number"||A.eg(a)||a==null)return J.aH(a)
if(typeof a=="string")return JSON.stringify(a)
return A.hh(a)},
br(a){return new A.bq(a)},
e_(a){return new A.a9(!1,null,null,a)},
bR(a,b,c,d,e){return new A.b7(b,c,!0,a,d,"Invalid value")},
hi(a,b,c){if(0>a||a>c)throw A.e(A.bR(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.e(A.bR(b,a,c,"end",null))
return b}return c},
eQ(a,b){if(a<0)throw A.e(A.bR(a,0,null,b,null))
return a},
e0(a,b,c,d){return new A.bx(b,!0,a,d,"Index out of range")},
eV(a){return new A.bX(a)},
F(a){return new A.bu(a)},
eI(a,b){return new A.ce(a,b)},
h9(a,b,c){var t,s
if(A.ep(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.a([],u.s)
B.a.p($.S,a)
try{A.ih(a,t)}finally{if(0>=$.S.length)return A.y($.S,-1)
$.S.pop()}s=A.eT(b,u.U.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
e1(a,b,c){var t,s
if(A.ep(a))return b+"..."+c
t=new A.aA(b)
B.a.p($.S,a)
try{s=t
s.a=A.eT(s.a,a,", ")}finally{if(0>=$.S.length)return A.y($.S,-1)
$.S.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
ih(a,b){var t,s,r,q,p,o,n,m=a.gn(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.l())return
t=A.x(m.gm())
B.a.p(b,t)
l+=t.length+2;++k}if(!m.l()){if(k<=5)return
if(0>=b.length)return A.y(b,-1)
s=b.pop()
if(0>=b.length)return A.y(b,-1)
r=b.pop()}else{q=m.gm();++k
if(!m.l()){if(k<=4){B.a.p(b,A.x(q))
return}s=A.x(q)
if(0>=b.length)return A.y(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gm();++k
for(;m.l();q=p,p=o){o=m.gm();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.y(b,-1)
l-=b.pop().length+2;--k}B.a.p(b,"...")
return}}r=A.x(q)
s=A.x(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.y(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.p(b,n)
B.a.p(b,r)
B.a.p(b,s)},
z:function z(){},
bq:function bq(a){this.a=a},
bb:function bb(){},
a9:function a9(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
b7:function b7(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bx:function bx(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bZ:function bZ(a){this.a=a},
bX:function bX(a){this.a=a},
bT:function bT(a){this.a=a},
bu:function bu(a){this.a=a},
ba:function ba(){},
ce:function ce(a,b){this.a=a
this.b=b},
c:function c(){},
ad:function ad(a,b,c){this.a=a
this.b=b
this.$ti=c},
b5:function b5(){},
w:function w(){},
aA:function aA(a){this.a=a},
aC(a,b,c,d,e,f,g,h,i){return A.p(f,1,new A.cA(e,f),d,h,a,g,e,c,A.a([B.a.gaE(a.split("-"))+".transfer"],u.s),i,b,new A.cB(e,f))},
t(a,b,c,d,e,f,g,h,i){var t=u.N,s=u.z,r=A.cl(t,s)
r.q(0,"items",d)
r.q(0,"choices",e)
r.q(0,"target",f)
t=A.d(["values",A.cm(d.length,-1,u.S)],t,s)
return A.aC(a,b,c,g,h,r,t,h==="clozeBank"?"\u0110\u1ecdc c\u1ea3 c\xe2u tr\u01b0\u1edbc v\xe0 sau ch\u1ed7 tr\u1ed1ng; m\u1ed7i t\u1eeb ph\u1ea3i \u0111\xfang c\u1ea3 ngh\u0129a v\xe0 ng\u1eef c\u1ea3nh.":"Gh\xe9p theo quan h\u1ec7 \u0111\u01b0\u1ee3c h\u1ecfi; kh\xf4ng d\u1ef1a v\xe0o v\u1ecb tr\xed c\u1ee7a th\u1ebb.",i)},
U(a,b,c,d,e,f,g){var t,s=u.N,r=u.z,q=A.d(["items",d,"target",e],s,r),p=d.length,o=J.av(p,u.S)
for(t=0;t<p;++t)o[t]=t
return A.aC(a,b,c,f,"sequenceTiles",q,A.d(["values",o],s,r),"D\xf9ng m\u0169i t\xean ho\u1eb7c k\xe9o th\u1ebb \u0111\u1ec3 \u0111\u1ed5i th\u1ee9 t\u1ef1; ki\u1ec3m tra quan h\u1ec7 tr\u01b0\u1edbc\u2013sau.",g)},
L(a,b,c,d,e,f){var t=u.N,s=u.z
return A.aC(a,b,c,f,"evidenceBoard",A.d(["items",d,"target",e],t,s),A.d(["selected",A.a([],u.t)],t,s),"C\xf3 th\u1ec3 ch\u1ecdn nhi\u1ec1u th\u1ebb. Ph\xe2n bi\u1ec7t d\u1eef ki\u1ec7n quan s\xe1t \u0111\u01b0\u1ee3c v\u1edbi \xfd ki\u1ebfn v\xe0 k\u1ebft lu\u1eadn v\u01b0\u1ee3t b\u1eb1ng ch\u1ee9ng.","Th\u1eed th\xe1ch")},
eh(a,b,c,d,e,f,g){var t=u.N,s=u.z
return A.aC(a,b,c+" M\xf4 h\xecnh gi\u1ea3n l\u01b0\u1ee3c: k\u1ebft qu\u1ea3 = "+d+" \xd7 "+e+". M\u1ed7i tham s\u1ed1 t\u1eeb 0 \u0111\u1ebfn 3. T\u1ea1o k\u1ebft qu\u1ea3 "+f+", d\u1ef1 \u0111o\xe1n r\u1ed3i ch\u1ea1y th\u1eed.",g,"causalExperiment",A.d(["axes",A.a([d,e],u.s),"goal",f],t,s),A.d(["x",0,"y",0,"prediction",-1,"observed",A.a([],u.t),"trials",[]],t,s),"\u0110\u1ed5i m\u1ed9t y\u1ebfu t\u1ed1 m\u1ed7i l\u1ea7n \u0111\u1ec3 nh\xecn r\xf5 t\xe1c \u0111\u1ed9ng. Ghi nh\u1edb gi\u1edbi h\u1ea1n 0\u20133.","Th\u1eed th\xe1ch")},
c9(a,b,c,d,e,f){var t=u.N,s=u.z
return A.aC(a,b,c+" Ph\xe2n b\u1ed5 \u0111\xfang 10 \u0111\u01a1n v\u1ecb; m\u1ed7i m\u1ee5c ph\u1ea3i \u0111\u1ea1t m\u1ee9c t\u1ed1i thi\u1ec3u ghi b\xean d\u01b0\u1edbi.",f,"resourceBudget",A.d(["items",d,"minima",e],t,s),A.d(["values",A.cm(d.length,0,u.S)],t,s),"\u0110\xe1p \u1ee9ng c\xe1c m\u1ee9c t\u1ed1i thi\u1ec3u tr\u01b0\u1edbc, r\u1ed3i ph\xe2n b\u1ed5 ph\u1ea7n c\xf2n l\u1ea1i. C\xf3 th\u1ec3 c\xf3 nhi\u1ec1u ph\u01b0\u01a1ng \xe1n \u0111\xfang.","Th\u1eed th\xe1ch")},
fe(a,b,c,d,e,f,g){var t=u.N,s=u.z
return A.aC(a,b,"Nghe c\xe2u ti\u1ebfng Anh r\u1ed3i ch\u1ecdn \xfd \u0111\xfang. C\xf3 th\u1ec3 nghe ch\u1eadm, nghe l\u1ea1i ho\u1eb7c m\u1edf b\u1ea3n ch\u1eef.",f,"listeningChoice",A.d(["text",c,"choices",d,"target",e],t,s),A.d(["answer",-1,"experienced",!1],t,s),"Ch\xfa \xfd h\xe0nh \u0111\u1ed9ng, th\u1eddi gian v\xe0 nh\u1eefng t\u1eeb ph\u1ee7 \u0111\u1ecbnh trong c\xe2u.",g)},
fi(a,b,c,d,e,f,g){var t=u.N,s=u.z
return A.aC(a,b,c,f,"speechPractice",A.d(["text",d,"accepted",e],t,s),A.d(["response",""],t,s),"Nghe c\xe2u m\u1eabu, n\xf3i t\u1eebng c\u1ee5m ng\u1eafn. C\xf3 th\u1ec3 nh\u1eadp c\xe2u n\u1ebfu kh\xf4ng d\xf9ng micro.",g)},
cB:function cB(a,b){this.a=a
this.b=b},
cA:function cA(a,b){this.a=a
this.b=b},
fo(a){var t,s=A.eR("[^a-z0-9\\s']")
s=A.et(a.toLowerCase(),s," ")
s=A.et(s,"'","")
t=A.eR("\\s+")
return B.e.aJ(A.et(s,t," "))},
cJ(a,b,c){var t
if(u.j.b(a)){t=J.o(a)
t=t.gi(a)===b&&t.t(a,new A.cK(c))}else t=!1
return t},
el(a,b){var t,s,r,q=J.o(a),p=J.o(b)
if(q.gi(a)===p.gi(b)){t=q.gi(a)
s=J.av(t,u.y)
for(r=0;r<t;++r)s[r]=J.f(q.h(a,r),p.h(b,r))
q=B.a.t(s,new A.d0())}else q=!1
return q},
fm(a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0="target",a1="values",a2="observed",a3=!1
switch(a4){case"matchPairs":case"categorySort":case"clozeBank":t=u.j
s=t.a(a5.h(0,a0))
r=a6.h(0,a1)
q=J.V(t.a(a5.h(0,"choices")))
a3=A.cJ(r,J.V(s),q)&&A.el(t.a(r),s)
p="check-connections"
break
case"sequenceTiles":t=u.j
s=t.a(a5.h(0,a0))
r=a6.h(0,a1)
o=J.o(s)
if(A.cJ(r,o.gi(s),o.gi(s))){t.a(r)
a3=J.dZ(r).a===o.gi(s)&&A.el(r,s)}p="check-order"
break
case"evidenceBoard":t=u.j
s=t.a(a5.h(0,a0))
n=a6.h(0,"selected")
o=J.o(s)
if(A.cJ(n,o.gi(s),J.V(t.a(a5.h(0,"items")))))if(t.b(n)){t=J.Z(n)
t=t.H(n).a===t.gi(n)&&t.t(n,o.gT(s))
a3=t}p="check-evidence"
break
case"listeningChoice":a3=J.f(a6.h(0,"experienced"),!0)&&A.u(a6.h(0,"answer"))&&J.f(a6.h(0,"answer"),a5.h(0,a0))
p="listen-and-compare"
break
case"speechPractice":m=a6.h(0,"response")
a3=typeof m=="string"&&m.length<=500&&J.fR(u.j.a(a5.h(0,"accepted")),new A.ds(m))
p="compare-phrase"
break
case"causalExperiment":l=a6.h(0,"x")
k=a6.h(0,"y")
j=a6.h(0,"prediction")
if(A.u(l)&&A.u(k)&&l>=0&&l<=3&&k>=0&&k<=3&&A.u(j)){t=l*k
if(t===a5.h(0,"goal"))if(j===t){o=u.j
t=o.b(a6.h(0,a2))&&J.fT(o.a(a6.h(0,a2)),new A.dt())&&A.el(o.a(a6.h(0,a2)),[l,k,t])
a3=t}}p="predict-run-compare"
break
case"resourceBudget":r=a6.h(0,a1)
t=u.j
i=t.a(a5.h(0,"minima"))
o=J.o(i)
if(A.cJ(r,o.gi(i),11)){h=J.cc(t.a(r),u.S)
if(h.a4(h,new A.du())===10){t=h.a
g=J.o(t)
f=g.gi(t)
e=J.av(f,u.y)
for(d=h.$ti.y[1],c=0;c<f;++c){b=d.a(g.h(t,c))
a=A.D(o.h(i,c))
if(typeof b!=="number")return b.a5()
e[c]=b>=a}a3=B.a.t(e,new A.dv())}}p="check-resources"
break
default:p="complete-model"}t=a3?"understood":p
o=a3?A.a(["model-complete"],u.s):B.b
return new A.M(a3,a3?B.b:A.a([p],u.s),o,t)},
cK:function cK(a){this.a=a},
d0:function d0(){},
ds:function ds(a){this.a=a},
dt:function dt(){},
du:function du(){},
dv:function dv(){},
J(a,b,c,d,e,f,g,h,i,j,k,l,m,n){var t=A.a([f],u.s),s=u.N,r=u.z,q=A.d(["answer",-1,"reason",-1],s,r)
r=A.cl(s,r)
r.q(0,"knowledge",g)
r.q(0,"choices",b)
r.q(0,"reasons",j)
r.q(0,"source",k)
if(c!=null)r.q(0,"code",c)
if(m!=null)r.q(0,"swatches",m)
return A.p(r,1,new A.dM(b,j,a,i),d,e,f,q,"reasonedChoice",h,t,l,n,new A.dN(a,i))},
dN:function dN(a,b){this.a=a
this.b=b},
dM:function dM(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
cb(a,b){var t,s,r,q,p=J.o(a)
if(p.gi(a)===b.length){t=p.gi(a)
s=J.av(t,u.y)
for(r=0;r<t;++r){q=p.h(a,r)
if(!(r<b.length))return A.y(b,r)
s[r]=J.f(q,b[r])}p=B.a.t(s,new A.d1())}else p=!1
return p},
fs(a,b){var t,s,r,q,p,o,n=A.hg(b,u.S)
for(t=a.$ti,s=new A.a3(a,a.gi(0),t.j("a3<j.E>")),t=t.j("j.E");s.l();){r=s.d
if(r==null)r=t.a(r)
if(r<0||r>2)throw A.e(A.e_("Comparator ngo\xe0i b\u1ed1n d\xe2y"))
q=n.length
if(r>>>0!==r||r>=q)return A.y(n,r)
p=n[r]
o=r+1
if(!(o<q))return A.y(n,o)
q=n[o]
if(p>q){n[r]=q
n[o]=p}}return n},
d1:function d1(){},
db:function db(){},
da:function da(){},
d3:function d3(){},
dc:function dc(){},
dd:function dd(){},
d9:function d9(){},
df:function df(){},
dg:function dg(){},
dh:function dh(){},
d7:function d7(){},
d8:function d8(a){this.a=a},
di:function di(){},
dj:function dj(){},
dk:function dk(){},
d6:function d6(){},
dl:function dl(){},
d4:function d4(){},
d5:function d5(){},
dm:function dm(){},
de:function de(){},
dp:function dp(){},
dq:function dq(){},
dr:function dr(){},
p(a,b,c,d,e,f,g,h,i,j,k,l,m){return new A.r(f,h,g,m,c,b,a)},
M:function M(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
r:function r(a,b,c,d,e,f,g){var _=this
_.a=a
_.f=b
_.r=c
_.w=d
_.y=e
_.Q=f
_.at=g},
ef(a,b){var t,s,r,q=!1
if(u.j.b(a)){t=J.o(a)
if(t.gi(a)===3){s=J.av(3,u.y)
for(r=0;r<3;++r)s[r]=J.f(t.h(a,r),b[r])
q=B.a.t(s,new A.cL())}}return q},
ej(a,b,c,d){var t=""+c,s=u.N,r=u.z
return A.p(A.d(["extra",c,"total",d],s,r),1,null,"B\u1edbt "+t+" \u1edf c\u1ea3 hai v\u1ebf b\u1ea3o to\xe0n \u0111\u1eb3ng th\u1ee9c: x = "+(d-c)+". Gi\xe1 tr\u1ecb thay \u0111\u1ed5i, quy t\u1eafc c\xe2n b\u1eb1ng v\u1eabn gi\u1eef nguy\xean.","Quan s\xe1t l\u01b0\u1ee3ng c\xf2n c\u1ed9ng v\u1edbi x. M\u1ed7i thao t\xe1c ph\u1ea3i gi\u1eef hai v\u1ebf b\u1eb1ng nhau.",a,A.d(["pairs",0],s,r),"removeBothSides","M\xf4 h\xecnh \u0111ang bi\u1ec3u di\u1ec5n x + "+t+" = "+d+". Gi\u1eef c\xe2n b\u1eb1ng v\xe0 c\xf4 l\u1eadp x b\u1eb1ng c\xe1ch b\u1ecf c\xf9ng m\u1ed9t l\u01b0\u1ee3ng \u1edf hai v\u1ebf.",B.b,"V\u1eadn d\u1ee5ng",b,new A.cX(c))},
ff(a,b,c,d){return A.p(B.c,1,null,"Ph\u1ea7n t\xf4 l\xe0 "+d+"/8; ph\u1ea7n ch\u01b0a t\xf4 l\xe0 "+(8-d)+"/8. M\u1ed9t t\u1ed5ng th\u1ec3 cho ph\xe9p di\u1ec5n t\u1ea3 c\u1ea3 ph\u1ea7n v\xe0 ph\u1ea7n b\xf9.","\u0110\u1ed5i v\u1ec1 nh\u1eefng ph\u1ea7n c\xf3 m\u1eabu s\u1ed1 8. C\xf3 th\u1ec3 ch\u1ea1m l\u1ea1i \u0111\u1ec3 b\u1ecf m\xe0u m\u1ed9t l\xe1t.",a,A.d(["painted",A.a([],u.t)],u.N,u.z),"fractionPaint",c+" T\u1ef1 t\xf4 tr\xean chi\u1ebfc b\xe1nh chia 8 l\xe1t b\u1eb1ng nhau.",B.b,"V\u1eadn d\u1ee5ng",b,new A.cT(d))},
ei(a,b,c,d){return A.p(B.c,1,null,"T\u1ed5ng qu\xe3ng \u0111\u01b0\u1eddng b\u1eb1ng t\u1ed5ng di\u1ec7n t\xedch d\u01b0\u1edbi t\u1eebng \u0111o\u1ea1n t\u1ed1c \u0111\u1ed9. C\xf9ng m\u1ed9t qu\xe3ng \u0111\u01b0\u1eddng c\xf3 th\u1ec3 c\xf3 nhi\u1ec1u l\u1ecbch tr\xecnh; c\xe1c \u0111i\u1ec1u ki\u1ec7n ph\u1ee5 quy\u1ebft \u0111\u1ecbnh l\u1ecbch tr\xecnh ph\xf9 h\u1ee3p.","Qu\xe3ng \u0111\u01b0\u1eddng m\u1ed7i \xf4 = t\u1ed1c \u0111\u1ed9 \xd7 2. Th\u1eddi gian ngh\u1ec9 v\u1eabn tr\xf4i, nh\u01b0ng qu\xe3ng \u0111\u01b0\u1eddng kh\xf4ng t\u0103ng.",a,A.d(["segments",A.a([-1,-1,-1],u.t)],u.N,u.z),"motionTimeline",c+" M\u1ed7i \xf4 d\xe0i 2 gi\xe2y; \u0111i ch\u1eadm 1 m/s, \u0111i nhanh 2 m/s. Gh\xe9p th\u1ebb r\u1ed3i \u0111\u1ecdc \u0111\u01b0\u1eddng \u0111i.",B.b,"Th\u1eed th\xe1ch",b,new A.cQ(d))},
ed(a,b,c,d,e){return A.p(B.c,1,null,"T\u1ed5ng "+B.a.a4(c,new A.cF())+" t\u1ea7ng kh\xf4ng \u0111\u1ed5i sau m\u1ed7i l\u1ea7n chuy\u1ec3n. M\xf4 h\xecnh "+B.a.a3(e," \u2013 ")+" th\u1ecfa \u0111\u1ed3ng th\u1eddi t\u1ed5ng v\xe0 c\xe1c quan h\u1ec7 \u0111\u1ec1 b\xe0i.","T\u1ed5ng s\u1ed1 t\u1ea7ng \u0111\u01b0\u1ee3c b\u1ea3o to\xe0n. D\xf9ng t\u1ed5ng v\xe0 quan h\u1ec7 gi\u1eefa c\xe1c t\xf2a \u0111\u1ec3 t\xecm m\xf4 h\xecnh ph\xf9 h\u1ee3p.",a,A.d(["heights",c],u.N,u.z),"redistributeMean",d+" Chuy\u1ec3n t\u1ea7ng gi\u1eefa ba t\xf2a; kh\xf4ng \u0111\u01b0\u1ee3c th\xeam hay b\u1ecf t\u1ea7ng.",B.b,"Th\u1eed th\xe1ch",b,new A.cG(e))},
fg(a,b,c,d){var t=""+c,s=u.t
return A.p(B.c,1,null,"Di\u1ec7n t\xedch r\xe0ng bu\u1ed9c t\xedch hai c\u1ea1nh; chu vi r\xe0ng bu\u1ed9c t\u1ed5ng hai c\u1ea1nh. M\u1ed9t m\xf4 h\xecnh ph\u1ea3i \u0111\xe1p \u1ee9ng c\u1ea3 hai \u0111i\u1ec1u ki\u1ec7n.","T\xecm hai c\u1ea1nh v\u1eeba c\xf3 t\xedch b\u1eb1ng "+t+", v\u1eeba c\xf3 t\u1ed5ng b\u1eb1ng "+(d/2|0)+". Kh\xf4ng ch\u1ec9 ki\u1ec3m tra di\u1ec7n t\xedch.",a,A.d(["points",A.a([A.a([0,0],s),A.a([4,0],s),A.a([4,4],s),A.a([0,4],s)],u.p)],u.N,u.z),"polygonVertices","K\xe9o b\u1ed1n \u0111\u1ec9nh th\xe0nh h\xecnh ch\u1eef nh\u1eadt c\xf3 di\u1ec7n t\xedch "+t+" \xf4 vu\xf4ng v\xe0 chu vi "+d+" \u0111\u01a1n v\u1ecb. M\u1ed7i kho\u1ea3ng l\u01b0\u1edbi d\xe0i 1 \u0111\u01a1n v\u1ecb.",B.b,"Th\u1eed th\xe1ch",b,new A.cW(c,d))},
ek(a,b,c,d){var t=d==null?"":" Tr\u01b0\u1edbc khi t\u1edbi \u0111\xedch, ph\u1ea3i qua c\u1ed9t "+(d[0]+1)+", h\xe0ng "+(d[1]+1)+" (\u0111\u1ebfm t\u1eeb g\xf3c tr\xe1i tr\xean).",s=c.length===0?"":" \u0110\u01b0\u1eddng hi\u1ec7n t\u1ea1i c\xf3 l\u1ed7i: d\xf9ng n\xfat l\xf9i \u0111\u1ec3 s\u1eeda."
return A.p(B.c,1,null,"Thu\u1eadt to\xe1n t\u1ed1t v\u1eeba \u0111i \u0111\xfang, v\u1eeba tu\xe2n th\u1ee7 gi\u1edbi h\u1ea1n t\xe0i nguy\xean. \u0110\u01b0\u1eddng \u0111i c\u1ee7a b\u1ea1n v\u01b0\u1ee3t qua \u0111\xe1, \u0111\u1ebfn \u0111\xedch v\xe0 \u0111\xe1p \u1ee9ng gi\u1edbi h\u1ea1n 6 l\u1ec7nh.","M\u1ed7i b\u01b0\u1edbc ch\u1ec9 thay \u0111\u1ed5i m\u1ed9t t\u1ecda \u0111\u1ed9. Quan s\xe1t \u0111\u01b0\u1eddng v\u1ebd v\xe0 lo\u1ea1i c\xe1c b\u01b0\u1edbc v\xf2ng l\u1ea1i kh\xf4ng c\u1ea7n thi\u1ebft.",a,A.d(["commands",c],u.N,u.z),"robotRoute","D\u1eabn robot t\u1edbi sao b\u1eb1ng t\u1ed1i \u0111a 6 l\u1ec7nh, tr\xe1nh \u0111\xe1 v\xe0 m\xe9p b\u1ea3n \u0111\u1ed3."+t+s,B.b,"Th\u1eed th\xe1ch",b,new A.cY(6,d))},
fd(a,b,c,d,e){var t,s,r="M\u1eabu "+c,q=A.Q(e)
q=new A.b0(e,q.j("b(1)").a(new A.cN()),q.j("b0<1,b>")).a3(0,"% \u2013 ")
t=u.N
s=u.z
return A.p(A.d(["color",d,"colorLabel",r],t,s),1,null,r+" \u0111\u01b0\u1ee3c t\u1ea1o b\u1edfi m\u1ee9c \u0111\u1ecf\u2013l\u1ee5c\u2013lam "+q+"%. C\u1ed9ng c\xe1c ch\xf9m s\xe1ng thay \u0111\u1ed5i c\u1ea3 s\u1eafc v\xe0 \u0111\u1ed9 s\xe1ng.","Th\u1eed b\u1eadt t\u1eebng c\u1eb7p ngu\u1ed3n, r\u1ed3i c\u1ea3 ba ngu\u1ed3n. \u0110\xe2y l\xe0 pha \xe1nh s\xe1ng c\u1ed9ng, kh\xf4ng ph\u1ea3i pha s\u01a1n.",a,A.d(["rgb",A.a([0,0,0],u.n)],t,s),"colorMixer","\u0110i\u1ec1u ch\u1ec9nh ba ngu\u1ed3n s\xe1ng \u0111\u1ec3 kh\u1edbp m\u1eabu "+c+". Quan s\xe1t m\xe0u tr\u1ed9n khi t\u0103ng ho\u1eb7c gi\u1ea3m t\u1eebng ngu\u1ed3n.",B.b,"V\u1eadn d\u1ee5ng",b,new A.cO(e))},
f7(a,b,c,d,e){var t=""+c,s=""+d,r=u.N,q=u.z
return A.p(A.d(["capacity",c],r,q),1,null,"C\xf3 "+s+" vi\xean xanh v\xe0 "+(c-d)+" vi\xean \u0111\u1ecf, n\xean P(xanh) = "+s+"/"+t+". C\u01a1 h\u1ed9i thay \u0111\u1ed5i khi t\u1ec9 l\u1ec7 c\xe1c m\xe0u thay \u0111\u1ed5i.","Hai m\xe0u chia s\u1ebb c\xf9ng m\u1ed9t t\u1ed5ng. Chuy\u1ec3n \u0111i\u1ec1u ki\u1ec7n \u0111\u1ec1 b\xe0i th\xe0nh s\u1ed1 vi\xean c\u1ee7a t\u1eebng m\xe0u r\u1ed3i ki\u1ec3m tra l\u1ea1i c\u1ea3 t\xfai.",a,A.d(["balls",A.a([],u.s)],r,q),"probabilityBag",e+" D\u1ef1ng t\xfai g\u1ed3m \u0111\xfang "+t+" vi\xean b\u1eb1ng c\xe1ch th\xeam ho\u1eb7c l\u1ea5y bi ra.",B.b,"Th\u1eed th\xe1ch",b,new A.cE(c,d))},
cL:function cL(){},
cX:function cX(a){this.a=a},
cT:function cT(a){this.a=a},
cR:function cR(){},
cQ:function cQ(a){this.a=a},
cP:function cP(){},
cF:function cF(){},
cG:function cG(a){this.a=a},
cW:function cW(a,b){this.a=a
this.b=b},
cV:function cV(){},
cU:function cU(){},
cY:function cY(a,b){this.a=a
this.b=b},
cN:function cN(){},
cO:function cO(a){this.a=a},
cM:function cM(){},
cE:function cE(a,b){this.a=a
this.b=b},
cC:function cC(){},
cD:function cD(){},
dB:function dB(){},
dC:function dC(){},
dD:function dD(){},
dE:function dE(){},
dz:function dz(){},
dA:function dA(){},
iD(a){var t,s,r=u.P.a(a).h(0,"position")
if(!A.u(r)||r<0||r>8)return B.d
t=r===6
s=A.a(["valid-position"],u.s)
if(t)s.push("equivalent-fraction")
return new A.M(t,B.b,s,t?"fraction-match":"fraction-position")},
iE(a){var t,s,r=u.P.a(a).h(0,"painted")
if(u.j.b(r)){t=J.Z(r)
t=t.J(r,new A.dw())||t.H(r).a!==t.gi(r)}else t=!0
if(t)return B.d
s=J.V(r)===3
t=A.a(["valid-slices"],u.s)
if(s)t.push("target-fraction")
return new A.M(s,B.b,t,s?"fraction-match":"fraction-count")},
dw:function dw(){},
hS(a){return J.f(u.P.a(a).h(0,"blocks"),4)},
iq(a){return J.f(u.P.a(a).h(0,"pairs"),3)},
hZ(a){return J.f(u.P.a(a).h(0,"turns"),2)},
im(a){var t,s=u.P.a(a).h(0,"painted")
if(u.j.b(s)){t=J.o(s)
t=t.gi(s)===3&&t.H(s).a===3&&t.t(s,new A.cS())}else t=!1
return t},
hY(a){return J.f(u.P.a(a).h(0,"folds"),2)},
hX(a){return A.ca(u.P.a(a).h(0,"baskets"),A.a([3,3,3],u.t))},
ii(a){var t
u.P.a(a)
t=A.eb(a.h(0,"angle"))
return Math.abs((t==null?0:t)-45)<=3&&J.f(a.h(0,"launched"),!0)},
il(a){return A.ca(u.P.a(a).h(0,"segments"),A.a([2,0,1],u.t))},
ij(a){return J.f(u.P.a(a).h(0,"position"),3)},
it(a){return A.ca(u.P.a(a).h(0,"order"),A.a([1,2,3,4],u.t))},
hT(a){return A.ca(u.P.a(a).h(0,"bins"),A.a([0,0,1,1,2,2],u.t))},
ik(a){return A.ca(u.P.a(a).h(0,"heights"),A.a([4,4,4],u.t))},
ca(a,b){var t,s,r,q,p,o=!1
if(u.j.b(a)){t=J.o(a)
s=t.gi(a)
r=b.length
if(s===r){q=J.av(r,u.y)
for(p=0;p<r;++p){o=t.h(a,p)
if(!(p<b.length))return A.y(b,p)
q[p]=J.f(o,b[p])}o=B.a.t(q,new A.cI())}}return o},
cS:function cS(){},
cI:function cI(){},
ir(a){var t,s,r,q,p,o,n,m,l
A.a7(a)
try{p=u.P
t=p.a(B.f.aA(a,null))
o=$.fP()
n=A.q(o).j("b_<2>")
s=new A.aL(new A.b_(o,n),n.j("c<r>(c.E)").a(new A.cZ()),n.j("aL<c.E,r>")).aF(0,new A.d_(t))
r=p.a(J.v(t,"state"))
q=s.aD(r)
m=B.f.ag(A.d(["is_correct",q.a,"misconception_codes",q.b,"satisfied_constraints",q.c,"feedback_key",q.d,"mechanism",s.f,"evaluator_version",2,"config",s.at,"initial_state",s.r],u.N,u.K),null)
return m}catch(l){p=u.N
m=B.f.ag(A.d(["error","unsupported_activity_or_invalid_state"],p,p),null)
return m}},
iT(){var t,s=v.G.globalThis
if(typeof A.er()=="function")A.dW(A.e_("Attempting to rewrap a JS function."))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.hU,A.er())
t[$.ex()]=A.er()
return s.matlingoEvaluate=t},
cZ:function cZ(){},
d_:function d_(a){this.a=a},
dO:function dO(){},
dP:function dP(){},
dQ:function dQ(){},
dR:function dR(){},
dS:function dS(){},
dT:function dT(){},
dU:function dU(){},
dV:function dV(){},
ew(a){return B.a.t(A.a(["width","height","depth"],u.s),new A.dY(a))},
es(a){return A.D(a.h(0,"width"))*A.D(a.h(0,"height"))*A.D(a.h(0,"depth"))},
ft(a){var t=A.D(a.h(0,"width")),s=A.D(a.h(0,"height")),r=A.D(a.h(0,"depth"))
return 2*(t*s+t*r+s*r)},
fx(a){var t
if(u.j.b(a)){t=J.o(a)
t=t.gi(a)===3&&t.t(a,new A.dX())&&J.f(t.h(a,0),10)&&J.f(t.h(a,1),20)&&J.f(t.h(a,2),30)}else t=!1
return t},
dY:function dY(a){this.a=a},
dX:function dX(){},
dx(a,b){var t,s,r,q,p,o,n,m,l,k,j,i="volume",h="solid-match",g="volume-mismatch",f="latitude",e="longitude",d=a==="geometry-solid-volume"
if(d||a==="algebra-solid-relation"){if(!A.ew(b))return B.d
t=A.es(b)
s=A.a([],u.s)
if(d){if(t===12)B.a.p(s,i)
if(A.ft(b)===32)B.a.p(s,"surface")
d=s.length===2
if(d)r=h
else r=B.a.v(s,i)?"surface-mismatch":g
return new A.M(d,B.b,s,r)}if(t===16)B.a.p(s,i)
if(J.f(b.h(0,"width"),2*A.af(b.h(0,"height"))))B.a.p(s,"double-height")
if(J.f(b.h(0,"depth"),b.h(0,"height")))B.a.p(s,"equal-depth")
d=s.length===3
if(d)r=h
else r=B.a.v(s,i)?"relation-mismatch":g
return new A.M(d,B.b,s,r)}if(a==="geography-globe-grid"){q=b.h(0,f)
p=b.h(0,e)
if(!A.u(q)||!A.u(p)||q<-90||q>90||p<-180||p>180)return B.d
d=A.a([],u.s)
r=q===15
if(r)d.push(f)
if(p===105)d.push(e)
o=d.length===2
if(o)r="coordinate-match"
else r=!r?"latitude-mismatch":"longitude-mismatch"
return new A.M(o,B.b,d,r)}n=b.h(0,"layers")
d=!0
if(a==="geography-rock-layers")if(u.j.b(n)){d=J.o(n)
d=d.gi(n)!==3||d.H(n).a!==3||d.J(n,new A.dy())}if(d)return B.d
m=A.fx(n)
d=A.a([],u.s)
for(r=J.o(n),l=0;l<2;l=k){o=r.h(n,l)
k=l+1
j=r.h(n,k)
if(typeof o!=="number")return o.aO()
if(typeof j!=="number")return A.dG(j)
if(o<j)d.push("order-"+l)}return new A.M(m,B.b,d,m?"layers-match":"layer-order-mismatch")},
dy:function dy(){},
fu(a){return v.mangledGlobalNames[a]},
j9(a){throw A.I(new A.bE("Field '"+a+"' has been assigned during initialization."),new Error())},
hU(a,b,c){u.Z.a(a)
if(A.D(c)>=1)return a.$1(b)
return a.$0()}},B={}
var w=[A,J,B]
var $={}
A.e2.prototype={}
J.by.prototype={
B(a,b){return a===b},
gD(a){return A.bP(a)},
k(a){return"Instance of '"+A.bQ(a)+"'"},
gA(a){return A.ap(A.ee(this))}}
J.bA.prototype={
k(a){return String(a)},
gD(a){return a?519018:218159},
gA(a){return A.ap(u.y)},
$in:1,
$ik:1}
J.aP.prototype={
B(a,b){return null==b},
k(a){return"null"},
gD(a){return 0},
$in:1}
J.aT.prototype={$iC:1}
J.ac.prototype={
gD(a){return 0},
k(a){return String(a)}}
J.bO.prototype={}
J.aB.prototype={}
J.ab.prototype={
k(a){var t=a[$.fy()]
if(t==null)t=a[$.ex()]
if(t==null)return this.an(a)
return"JavaScript function for "+J.aH(t)},
$iau:1}
J.aS.prototype={
gD(a){return 0},
k(a){return String(a)}}
J.aU.prototype={
gD(a){return 0},
k(a){return String(a)}}
J.A.prototype={
S(a,b){return new A.a0(a,A.Q(a).j("@<1>").G(b).j("a0<1,2>"))},
p(a,b){A.Q(a).c.a(b)
a.$flags&1&&A.ev(a,29)
a.push(b)},
M(a,b){var t=A.Q(a)
return new A.a5(a,t.j("k(1)").a(b),t.j("a5<1>"))},
E(a,b){var t
A.Q(a).j("c<1>").a(b)
a.$flags&1&&A.ev(a,"addAll",2)
if(Array.isArray(b)){this.ap(a,b)
return}for(t=J.a8(b);t.l();)a.push(t.gm())},
ap(a,b){var t,s
u.b.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.e(A.F(a))
for(s=0;s<t;++s)a.push(b[s])},
a3(a,b){var t,s=A.cm(a.length,"",u.N)
for(t=0;t<a.length;++t)this.q(s,t,A.x(a[t]))
return s.join(b)},
a4(a,b){var t,s,r
A.Q(a).j("1(1,1)").a(b)
t=a.length
if(t===0)throw A.e(A.aN())
if(0>=t)return A.y(a,0)
s=a[0]
for(r=1;r<t;++r){s=b.$2(s,a[r])
if(t!==a.length)throw A.e(A.F(a))}return s},
C(a,b){if(!(b>=0&&b<a.length))return A.y(a,b)
return a[b]},
gaE(a){if(a.length>0)return a[0]
throw A.e(A.aN())},
gaI(a){var t=a.length
if(t>0)return a[t-1]
throw A.e(A.aN())},
J(a,b){var t,s
A.Q(a).j("k(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(b.$1(a[s]))return!0
if(a.length!==t)throw A.e(A.F(a))}return!1},
t(a,b){var t,s
A.Q(a).j("k(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(!b.$1(a[s]))return!1
if(a.length!==t)throw A.e(A.F(a))}return!0},
v(a,b){var t
for(t=0;t<a.length;++t)if(J.f(a[t],b))return!0
return!1},
gu(a){return a.length===0},
gL(a){return a.length!==0},
k(a){return A.e1(a,"[","]")},
H(a){return A.he(a,A.Q(a).c)},
gn(a){return new J.ag(a,a.length,A.Q(a).j("ag<1>"))},
gD(a){return A.bP(a)},
gi(a){return a.length},
h(a,b){if(!(b>=0&&b<a.length))throw A.e(A.d2(a,b))
return a[b]},
q(a,b,c){A.Q(a).c.a(c)
a.$flags&2&&A.ev(a)
if(!(b>=0&&b<a.length))throw A.e(A.d2(a,b))
a[b]=c},
$ih:1,
$ic:1,
$ii:1}
J.bz.prototype={
aK(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.bQ(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.cf.prototype={}
J.ag.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
l(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.eu(r)
throw A.e(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0},
$iB:1}
J.aQ.prototype={
k(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gD(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
ae(a,b){var t
if(a>0)t=this.az(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
az(a,b){return b>31?0:a>>>b},
gA(a){return A.ap(u.H)},
$il:1,
$iar:1}
J.aO.prototype={
gA(a){return A.ap(u.S)},
$in:1,
$ib:1}
J.bB.prototype={
gA(a){return A.ap(u.i)},
$in:1}
J.ai.prototype={
af(a,b){return new A.c7(b,a,0)},
P(a,b,c){return a.substring(b,A.hi(b,c,a.length))},
aJ(a){var t,s,r,q=a.trim(),p=q.length
if(p===0)return q
if(0>=p)return A.y(q,0)
if(q.charCodeAt(0)===133){t=J.ha(q,1)
if(t===p)return""}else t=0
s=p-1
if(!(s>=0))return A.y(q,s)
r=q.charCodeAt(s)===133?J.hb(q,s):p
if(t===0&&r===p)return q
return q.substring(t,r)},
k(a){return a},
gD(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gA(a){return A.ap(u.N)},
gi(a){return a.length},
$in:1,
$icp:1,
$im:1}
A.a6.prototype={
gn(a){return new A.aI(J.a8(this.gI()),A.q(this).j("aI<1,2>"))},
gi(a){return J.V(this.gI())},
gu(a){return J.fU(this.gI())},
gL(a){return J.fV(this.gI())},
C(a,b){return A.q(this).y[1].a(J.eC(this.gI(),b))},
v(a,b){return J.fS(this.gI(),b)},
k(a){return J.aH(this.gI())}}
A.aI.prototype={
l(){return this.a.l()},
gm(){return this.$ti.y[1].a(this.a.gm())},
$iB:1}
A.ah.prototype={
gI(){return this.a}}
A.be.prototype={$ih:1}
A.bd.prototype={
h(a,b){return this.$ti.y[1].a(J.v(this.a,b))},
$ih:1,
$ii:1}
A.a0.prototype={
S(a,b){return new A.a0(this.a,this.$ti.j("@<1>").G(b).j("a0<1,2>"))},
gI(){return this.a}}
A.bE.prototype={
k(a){return"LateInitializationError: "+this.a}}
A.h.prototype={}
A.a2.prototype={
gn(a){var t=this
return new A.a3(t,t.gi(t),A.q(t).j("a3<a2.E>"))},
gu(a){return this.gi(this)===0},
v(a,b){var t,s=this,r=s.gi(s)
for(t=0;t<r;++t){if(J.f(s.C(0,t),b))return!0
if(r!==s.gi(s))throw A.e(A.F(s))}return!1},
a3(a,b){var t,s,r,q=this,p=q.gi(q)
if(b.length!==0){if(p===0)return""
t=A.x(q.C(0,0))
if(p!==q.gi(q))throw A.e(A.F(q))
for(s=t,r=1;r<p;++r){s=s+b+A.x(q.C(0,r))
if(p!==q.gi(q))throw A.e(A.F(q))}return s.charCodeAt(0)==0?s:s}else{for(r=0,s="";r<p;++r){s+=A.x(q.C(0,r))
if(p!==q.gi(q))throw A.e(A.F(q))}return s.charCodeAt(0)==0?s:s}}}
A.a3.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
l(){var t,s=this,r=s.a,q=J.o(r),p=q.gi(r)
if(s.b!==p)throw A.e(A.F(r))
t=s.c
if(t>=p){s.d=null
return!1}s.d=q.C(r,t);++s.c
return!0},
$iB:1}
A.b0.prototype={
gi(a){return J.V(this.a)},
C(a,b){return this.b.$1(J.eC(this.a,b))}}
A.a5.prototype={
gn(a){return new A.bc(J.a8(this.a),this.b,this.$ti.j("bc<1>"))}}
A.bc.prototype={
l(){var t,s
for(t=this.a,s=this.b;t.l();)if(s.$1(t.gm()))return!0
return!1},
gm(){return this.a.gm()},
$iB:1}
A.aL.prototype={
gn(a){return new A.aM(J.a8(this.a),this.b,B.m,this.$ti.j("aM<1,2>"))}}
A.aM.prototype={
gm(){var t=this.d
return t==null?this.$ti.y[1].a(t):t},
l(){var t,s,r=this,q=r.c
if(q==null)return!1
for(t=r.a,s=r.b;!q.l();){r.d=null
if(t.l()){r.c=null
q=J.a8(s.$1(t.gm()))
r.c=q}else return!1}r.d=r.c.gm()
return!0},
$iB:1}
A.aK.prototype={
l(){return!1},
gm(){throw A.e(A.aN())},
$iB:1}
A.K.prototype={}
A.bo.prototype={}
A.aJ.prototype={
gu(a){return this.gi(this)===0},
k(a){return A.e6(this)},
$iO:1}
A.G.prototype={
gi(a){return this.b.length},
gav(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
N(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
h(a,b){if(!this.N(b))return null
return this.b[this.a[b]]},
K(a,b){var t,s,r,q
this.$ti.j("~(1,2)").a(b)
t=this.gav()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])}}
A.b9.prototype={}
A.cq.prototype={
F(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
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
A.b6.prototype={
k(a){return"Null check operator used on a null value"}}
A.bC.prototype={
k(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.bY.prototype={
k(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.co.prototype={
k(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.aa.prototype={
k(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.fv(s==null?"unknown":s)+"'"},
$iau:1,
gaN(){return this},
$C:"$1",
$R:1,
$D:null}
A.bs.prototype={$C:"$2",$R:2}
A.bW.prototype={}
A.bU.prototype={
k(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.fv(t)+"'"}}
A.at.prototype={
B(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.at))return!1
return this.$_target===b.$_target&&this.a===b.a},
gD(a){return(A.j6(this.a)^A.bP(this.$_target))>>>0},
k(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.bQ(this.a)+"'")}}
A.bS.prototype={
k(a){return"RuntimeError: "+this.a}}
A.a1.prototype={
gi(a){return this.a},
gu(a){return this.a===0},
gO(){return new A.aj(this,A.q(this).j("aj<1>"))},
gah(){return new A.aW(this,A.q(this).j("aW<1,2>"))},
N(a){var t=this.b
if(t==null)return!1
return t[a]!=null},
E(a,b){A.q(this).j("O<1,2>").a(b).K(0,new A.cg(this))},
h(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.aG(b)},
aG(a){var t,s,r=this.d
if(r==null)return null
t=this.au(r,a)
s=this.aj(t,a)
if(s<0)return null
return t[s].b},
q(a,b,c){var t,s,r=this,q=A.q(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.a8(t==null?r.b=r.Z():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.a8(s==null?r.c=r.Z():s,b,c)}else r.aH(b,c)},
aH(a,b){var t,s,r,q,p=this,o=A.q(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.Z()
s=p.ai(a)
r=t[s]
if(r==null)t[s]=[p.a_(a,b)]
else{q=p.aj(r,a)
if(q>=0)r[q].b=b
else r.push(p.a_(a,b))}},
K(a,b){var t,s,r=this
A.q(r).j("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.e(A.F(r))
t=t.c}},
a8(a,b,c){var t,s=A.q(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.a_(b,c)
else t.b=c},
a_(a,b){var t=this,s=A.q(t),r=new A.ck(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else t.f=t.f.c=r;++t.a
t.r=t.r+1&1073741823
return r},
ai(a){return J.cd(a)&1073741823},
au(a,b){return a[this.ai(b)]},
aj(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.f(a[s].a,b))return s
return-1},
k(a){return A.e6(this)},
Z(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$ieN:1}
A.cg.prototype={
$2(a,b){var t=this.a,s=A.q(t)
t.q(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.q(this.a).j("~(1,2)")}}
A.ck.prototype={}
A.aj.prototype={
gi(a){return this.a.a},
gu(a){return this.a.a===0},
gn(a){var t=this.a
return new A.aY(t,t.r,t.e,this.$ti.j("aY<1>"))},
v(a,b){return this.a.N(b)}}
A.aY.prototype={
gm(){return this.d},
l(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.e(A.F(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}},
$iB:1}
A.b_.prototype={
gi(a){return this.a.a},
gu(a){return this.a.a===0},
gn(a){var t=this.a
return new A.aZ(t,t.r,t.e,this.$ti.j("aZ<1>"))}}
A.aZ.prototype={
gm(){return this.d},
l(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.e(A.F(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.b
s.c=t.c
return!0}},
$iB:1}
A.aW.prototype={
gi(a){return this.a.a},
gu(a){return this.a.a===0},
gn(a){var t=this.a
return new A.aX(t,t.r,t.e,this.$ti.j("aX<1,2>"))}}
A.aX.prototype={
gm(){var t=this.d
t.toString
return t},
l(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.e(A.F(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=new A.ad(t.a,t.b,s.$ti.j("ad<1,2>"))
s.c=t.c
return!0}},
$iB:1}
A.dH.prototype={
$1(a){return this.a(a)},
$S:5}
A.dI.prototype={
$2(a,b){return this.a(a,b)},
$S:9}
A.dJ.prototype={
$1(a){return this.a(A.a7(a))},
$S:10}
A.aR.prototype={
k(a){return"RegExp/"+this.a+"/"+this.b.flags},
gac(){var t=this,s=t.c
if(s!=null)return s
s=t.b
return t.c=A.eL(t.a,s.multiline,!s.ignoreCase,s.unicode,s.dotAll,"g")},
af(a,b){return new A.c_(this,b,0)},
ar(a,b){var t,s=this.gac()
if(s==null)s=A.ec(s)
s.lastIndex=b
t=s.exec(a)
if(t==null)return null
return new A.c6(t)},
$icp:1,
$ihj:1}
A.c6.prototype={
ga6(){return this.b.index},
ga1(){var t=this.b
return t.index+t[0].length},
$iaw:1,
$ib8:1}
A.c_.prototype={
gn(a){return new A.c0(this.a,this.b,this.c)}}
A.c0.prototype={
gm(){var t=this.d
return t==null?u.F.a(t):t},
l(){var t,s,r,q,p,o,n=this,m=n.b
if(m==null)return!1
t=n.c
s=m.length
if(t<=s){r=n.a
q=r.ar(m,t)
if(q!=null){n.d=q
p=q.ga1()
if(q.b.index===p){t=!1
if(r.b.unicode){r=n.c
o=r+1
if(o<s){if(!(r>=0&&r<s))return A.y(m,r)
r=m.charCodeAt(r)
if(r>=55296&&r<=56319){if(!(o>=0))return A.y(m,o)
t=m.charCodeAt(o)
t=t>=56320&&t<=57343}}}p=(t?p+1:p)+1}n.c=p
return!0}}n.b=n.d=null
return!1},
$iB:1}
A.bV.prototype={
ga1(){return this.a+this.c.length},
$iaw:1,
ga6(){return this.a}}
A.c7.prototype={
gn(a){return new A.c8(this.a,this.b,this.c)}}
A.c8.prototype={
l(){var t,s,r=this,q=r.c,p=r.b,o=p.length,n=r.a,m=n.length
if(q+o>m){r.d=null
return!1}t=n.indexOf(p,q)
if(t<0){r.c=m+1
r.d=null
return!1}s=t+o
r.d=new A.bV(t,p)
r.c=s===r.c?s+1:s
return!0},
gm(){var t=this.d
t.toString
return t},
$iB:1}
A.ax.prototype={
gA(a){return B.an},
$in:1}
A.b3.prototype={}
A.bF.prototype={
gA(a){return B.ao},
$in:1}
A.ay.prototype={
gi(a){return a.length},
$iN:1}
A.b1.prototype={
h(a,b){A.an(b,a,a.length)
return a[b]},
$ih:1,
$ic:1,
$ii:1}
A.b2.prototype={$ih:1,$ic:1,$ii:1}
A.bG.prototype={
gA(a){return B.ap},
$in:1}
A.bH.prototype={
gA(a){return B.aq},
$in:1}
A.bI.prototype={
gA(a){return B.ar},
h(a,b){A.an(b,a,a.length)
return a[b]},
$in:1}
A.bJ.prototype={
gA(a){return B.as},
h(a,b){A.an(b,a,a.length)
return a[b]},
$in:1}
A.bK.prototype={
gA(a){return B.at},
h(a,b){A.an(b,a,a.length)
return a[b]},
$in:1}
A.bL.prototype={
gA(a){return B.au},
h(a,b){A.an(b,a,a.length)
return a[b]},
$in:1}
A.bM.prototype={
gA(a){return B.av},
h(a,b){A.an(b,a,a.length)
return a[b]},
$in:1}
A.b4.prototype={
gA(a){return B.aw},
gi(a){return a.length},
h(a,b){A.an(b,a,a.length)
return a[b]},
$in:1}
A.bN.prototype={
gA(a){return B.ax},
gi(a){return a.length},
h(a,b){A.an(b,a,a.length)
return a[b]},
$in:1}
A.bf.prototype={}
A.bg.prototype={}
A.bh.prototype={}
A.bi.prototype={}
A.W.prototype={
j(a){return A.cy(v.typeUniverse,this,a)},
G(a){return A.hI(v.typeUniverse,this,a)}}
A.c2.prototype={}
A.cw.prototype={
k(a){return A.R(this.a,null)}}
A.c1.prototype={
k(a){return this.a}}
A.bk.prototype={}
A.ak.prototype={
gn(a){var t=this,s=new A.al(t,t.r,A.q(t).j("al<1>"))
s.c=t.e
return s},
gi(a){return this.a},
gu(a){return this.a===0},
gL(a){return this.a!==0},
v(a,b){var t,s
if(typeof b=="string"&&b!=="__proto__"){t=this.b
if(t==null)return!1
return u.g.a(t[b])!=null}else if(typeof b=="number"&&(b&1073741823)===b){s=this.c
if(s==null)return!1
return u.g.a(s[b])!=null}else return this.aq(b)},
aq(a){var t=this.d
if(t==null)return!1
return this.ab(t[this.aa(a)],a)>=0},
p(a,b){var t,s,r=this
A.q(r).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.a9(t==null?r.b=A.e8():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.a9(s==null?r.c=A.e8():s,b)}else return r.ao(b)},
ao(a){var t,s,r,q=this
A.q(q).c.a(a)
t=q.d
if(t==null)t=q.d=A.e8()
s=q.aa(a)
r=t[s]
if(r==null)t[s]=[q.W(a)]
else{if(q.ab(r,a)>=0)return!1
r.push(q.W(a))}return!0},
a9(a,b){A.q(this).c.a(b)
if(u.g.a(a[b])!=null)return!1
a[b]=this.W(b)
return!0},
W(a){var t=this,s=new A.c5(A.q(t).c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
aa(a){return J.cd(a)&1073741823},
ab(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.f(a[s].a,b))return s
return-1},
$ieO:1}
A.c5.prototype={}
A.al.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
l(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.e(A.F(r))
else if(s==null){t.d=null
return!1}else{t.d=t.$ti.j("1?").a(s.a)
t.c=s.b
return!0}},
$iB:1}
A.j.prototype={
gn(a){return new A.a3(a,this.gi(a),A.X(a).j("a3<j.E>"))},
C(a,b){return this.h(a,b)},
gu(a){return this.gi(a)===0},
gL(a){return!this.gu(a)},
v(a,b){var t,s=this.gi(a)
for(t=0;t<s;++t){if(J.f(this.h(a,t),b))return!0
if(s!==this.gi(a))throw A.e(A.F(a))}return!1},
t(a,b){var t,s
A.X(a).j("k(j.E)").a(b)
t=this.gi(a)
for(s=0;s<t;++s){if(!b.$1(this.h(a,s)))return!1
if(t!==this.gi(a))throw A.e(A.F(a))}return!0},
J(a,b){var t,s
A.X(a).j("k(j.E)").a(b)
t=this.gi(a)
for(s=0;s<t;++s){if(b.$1(this.h(a,s)))return!0
if(t!==this.gi(a))throw A.e(A.F(a))}return!1},
M(a,b){var t=A.X(a)
return new A.a5(a,t.j("k(j.E)").a(b),t.j("a5<j.E>"))},
a4(a,b){var t,s,r,q=this
A.X(a).j("j.E(j.E,j.E)").a(b)
t=q.gi(a)
if(t===0)throw A.e(A.aN())
s=q.h(a,0)
for(r=1;r<t;++r){s=b.$2(s,q.h(a,r))
if(t!==q.gi(a))throw A.e(A.F(a))}return s},
H(a){var t,s=A.e4(A.X(a).j("j.E"))
for(t=0;t<this.gi(a);++t)s.p(0,this.h(a,t))
return s},
S(a,b){return new A.a0(a,A.X(a).j("@<j.E>").G(b).j("a0<1,2>"))},
k(a){return A.e1(a,"[","]")}}
A.P.prototype={
K(a,b){var t,s,r,q=A.q(this)
q.j("~(P.K,P.V)").a(b)
for(t=this.gO(),t=t.gn(t),q=q.j("P.V");t.l();){s=t.gm()
r=this.h(0,s)
b.$2(s,r==null?q.a(r):r)}},
gi(a){var t=this.gO()
return t.gi(t)},
gu(a){var t=this.gO()
return t.gu(t)},
k(a){return A.e6(this)},
$iO:1}
A.cn.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.x(a)
s.a=(s.a+=t)+": "
t=A.x(b)
s.a+=t},
$S:6}
A.az.prototype={
gu(a){return this.a===0},
gL(a){return this.a!==0},
E(a,b){var t
A.q(this).j("c<1>").a(b)
for(t=b.gn(b);t.l();)this.p(0,t.gm())},
a0(a){var t,s
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.eu)(a),++s)if(!this.v(0,a[s]))return!1
return!0},
k(a){return A.e1(this,"{","}")},
C(a,b){var t,s,r,q=this
A.eQ(b,"index")
t=A.hs(q,q.r,A.q(q).c)
for(s=b;t.l();){if(s===0){r=t.d
return r==null?t.$ti.c.a(r):r}--s}throw A.e(A.e0(b,b-s,q,"index"))},
$ih:1,
$ic:1}
A.bj.prototype={}
A.c3.prototype={
h(a,b){var t,s=this.b
if(s==null)return this.c.h(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.aw(b):t}},
gi(a){return this.b==null?this.c.a:this.R().length},
gu(a){return this.gi(0)===0},
gO(){if(this.b==null){var t=this.c
return new A.aj(t,A.q(t).j("aj<1>"))}return new A.c4(this)},
N(a){if(this.b==null)return this.c.N(a)
return Object.prototype.hasOwnProperty.call(this.a,a)},
K(a,b){var t,s,r,q,p=this
u.E.a(b)
if(p.b==null)return p.c.K(0,b)
t=p.R()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.cH(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.e(A.F(p))}},
R(){var t=u.Y.a(this.c)
if(t==null)t=this.c=A.a(Object.keys(this.a),u.s)
return t},
aw(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.cH(this.a[a])
return this.b[a]=t}}
A.c4.prototype={
gi(a){return this.a.gi(0)},
C(a,b){var t=this.a
if(t.b==null)t=t.gO().C(0,b)
else{t=t.R()
if(!(b>=0&&b<t.length))return A.y(t,b)
t=t[b]}return t},
gn(a){var t=this.a
if(t.b==null){t=t.gO()
t=t.gn(t)}else{t=t.R()
t=new J.ag(t,t.length,A.Q(t).j("ag<1>"))}return t},
v(a,b){return this.a.N(b)}}
A.bt.prototype={}
A.bv.prototype={}
A.aV.prototype={
k(a){var t=A.bw(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.bD.prototype={
k(a){return"Cyclic error in JSON stringify"}}
A.ch.prototype={
aA(a,b){var t=A.io(a,this.gaB().a)
return t},
ag(a,b){var t=A.hr(a,this.gaC().b,null)
return t},
gaC(){return B.L},
gaB(){return B.K}}
A.cj.prototype={}
A.ci.prototype={}
A.cu.prototype={
al(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.e.P(a,s,r)
s=r+1
p=A.H(92)
t.a+=p
p=A.H(117)
t.a+=p
p=A.H(100)
t.a+=p
p=q>>>8&15
p=A.H(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.H(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.H(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.e.P(a,s,r)
s=r+1
p=A.H(92)
t.a+=p
switch(q){case 8:p=A.H(98)
t.a+=p
break
case 9:p=A.H(116)
t.a+=p
break
case 10:p=A.H(110)
t.a+=p
break
case 12:p=A.H(102)
t.a+=p
break
case 13:p=A.H(114)
t.a+=p
break
default:p=A.H(117)
t.a+=p
p=A.H(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.H(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.H(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.e.P(a,s,r)
s=r+1
p=A.H(92)
t.a+=p
p=A.H(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.e.P(a,s,n)},
V(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.e(new A.bD(a,null))}B.a.p(t,a)},
U(a){var t,s,r,q,p=this
if(p.ak(a))return
p.V(a)
try{t=p.b.$1(a)
if(!p.ak(t)){r=A.eM(a,null,p.gad())
throw A.e(r)}r=p.a
if(0>=r.length)return A.y(r,-1)
r.pop()}catch(q){s=A.fw(q)
r=A.eM(a,s,p.gad())
throw A.e(r)}},
ak(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.H.k(a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.al(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.V(a)
r.aL(a)
t=r.a
if(0>=t.length)return A.y(t,-1)
t.pop()
return!0}else if(u.f.b(a)){r.V(a)
s=r.aM(a)
t=r.a
if(0>=t.length)return A.y(t,-1)
t.pop()
return s}else return!1},
aL(a){var t,s,r=this.c
r.a+="["
t=J.Z(a)
if(t.gL(a)){this.U(t.h(a,0))
for(s=1;s<t.gi(a);++s){r.a+=","
this.U(t.h(a,s))}}r.a+="]"},
aM(a){var t,s,r,q,p,o,n=this,m={}
if(a.gu(a)){n.c.a+="{}"
return!0}t=a.gi(a)*2
s=A.cm(t,null,u.O)
r=m.a=0
m.b=!0
a.K(0,new A.cv(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.al(A.a7(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.y(s,o)
n.U(s[o])}q.a+="}"
return!0}}
A.cv.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.q(t,s.a++,a)
B.a.q(t,s.a++,b)},
$S:6}
A.ct.prototype={
gad(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.z.prototype={}
A.bq.prototype={
k(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bw(t)
return"Assertion failed"}}
A.bb.prototype={}
A.a9.prototype={
gY(){return"Invalid argument"+(!this.a?"(s)":"")},
gX(){return""},
k(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.gY()+r+p
if(!t.a)return o
return o+t.gX()+": "+A.bw(t.ga2())},
ga2(){return this.b}}
A.b7.prototype={
ga2(){return A.eb(this.b)},
gY(){return"RangeError"},
gX(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.x(r):""
else if(r==null)t=": Not greater than or equal to "+A.x(s)
else if(r>s)t=": Not in inclusive range "+A.x(s)+".."+A.x(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.x(s)
return t}}
A.bx.prototype={
ga2(){return A.D(this.b)},
gY(){return"RangeError"},
gX(){if(A.D(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gi(a){return this.f}}
A.bZ.prototype={
k(a){return"Unsupported operation: "+this.a}}
A.bX.prototype={
k(a){return"UnimplementedError: "+this.a}}
A.bT.prototype={
k(a){return"Bad state: "+this.a}}
A.bu.prototype={
k(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bw(t)+"."}}
A.ba.prototype={
k(a){return"Stack Overflow"},
$iz:1}
A.ce.prototype={
k(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException",r=this.b
if(typeof r=="string"){if(r.length>78)r=B.e.P(r,0,75)+"..."
return s+"\n"+r}else return s}}
A.c.prototype={
S(a,b){return A.fZ(this,A.q(this).j("c.E"),b)},
M(a,b){var t=A.q(this)
return new A.a5(this,t.j("k(c.E)").a(b),t.j("a5<c.E>"))},
v(a,b){var t
for(t=this.gn(this);t.l();)if(J.f(t.gm(),b))return!0
return!1},
t(a,b){var t
A.q(this).j("k(c.E)").a(b)
for(t=this.gn(this);t.l();)if(!b.$1(t.gm()))return!1
return!0},
J(a,b){var t
A.q(this).j("k(c.E)").a(b)
for(t=this.gn(this);t.l();)if(b.$1(t.gm()))return!0
return!1},
H(a){var t=A.e4(A.q(this).j("c.E"))
t.E(0,this)
return t},
gi(a){var t,s=this.gn(this)
for(t=0;s.l();)++t
return t},
gu(a){return!this.gn(this).l()},
gL(a){return!this.gu(this)},
aF(a,b){var t,s
A.q(this).j("k(c.E)").a(b)
for(t=this.gn(this);t.l();){s=t.gm()
if(b.$1(s))return s}throw A.e(A.aN())},
C(a,b){var t,s
A.eQ(b,"index")
t=this.gn(this)
for(s=b;t.l();){if(s===0)return t.gm();--s}throw A.e(A.e0(b,b-s,this,"index"))},
k(a){return A.h9(this,"(",")")}}
A.ad.prototype={
k(a){return"MapEntry("+A.x(this.a)+": "+A.x(this.b)+")"}}
A.b5.prototype={
gD(a){return A.w.prototype.gD.call(this,0)},
k(a){return"null"}}
A.w.prototype={$iw:1,
B(a,b){return this===b},
gD(a){return A.bP(this)},
k(a){return"Instance of '"+A.bQ(this)+"'"},
gA(a){return A.iK(this)},
toString(){return this.k(this)}}
A.aA.prototype={
gi(a){return this.a.length},
k(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ihl:1}
A.cB.prototype={
$1(a){return A.fm(this.a,this.b,u.P.a(a)).a},
$S:0}
A.cA.prototype={
$1(a){return A.fm(this.a,this.b,u.P.a(a))},
$S:2}
A.cK.prototype={
$1(a){return A.u(a)&&a>=0&&a<this.a},
$S:1}
A.d0.prototype={
$1(a){return A.aD(a)},
$S:3}
A.ds.prototype={
$1(a){return A.fo(A.a7(a))===A.fo(this.a)},
$S:1}
A.dt.prototype={
$1(a){return A.u(a)},
$S:1}
A.du.prototype={
$2(a,b){return A.D(a)+A.D(b)},
$S:7}
A.dv.prototype={
$1(a){return A.aD(a)},
$S:3}
A.dN.prototype={
$1(a){u.P.a(a)
return J.f(a.h(0,"answer"),this.a)&&J.f(a.h(0,"reason"),this.b)},
$S:0}
A.dM.prototype={
$1(a){var t,s,r,q,p,o,n=this
u.P.a(a)
t=a.h(0,"answer")
s=a.h(0,"reason")
if(!A.u(t)||!A.u(s)||t<0||t>=n.a.length||s<0||s>=n.b.length)return B.d
r=t===n.c
q=r&&s===n.d
p=A.a([],u.s)
if(r)p.push("answer")
o=s===n.d
if(o)p.push("reason")
if(!r)r="rethink-answer"
else r=!o?"rethink-reason":"correct"
return new A.M(q,B.b,p,r)},
$S:2}
A.d1.prototype={
$1(a){return A.aD(a)},
$S:3}
A.db.prototype={
$1(a){var t,s,r,q,p,o=u.j,n=J.cc(o.a(u.P.a(a).h(0,"points")),o)
o=n.a
t=J.o(o)
s=!1
if(t.gi(o)===4)if(n.t(n,new A.da())){r=n.$ti.y[1]
if(J.f(J.v(r.a(t.h(o,0)),1),J.v(r.a(t.h(o,1)),1)))if(J.f(J.v(r.a(t.h(o,1)),0),J.v(r.a(t.h(o,2)),0)))if(J.f(J.v(r.a(t.h(o,2)),1),J.v(r.a(t.h(o,3)),1)))if(J.f(J.v(r.a(t.h(o,3)),0),J.v(r.a(t.h(o,0)),0))){s=J.v(r.a(t.h(o,1)),0)
q=J.v(r.a(t.h(o,0)),0)
if(typeof s!=="number")return s.a7()
if(typeof q!=="number")return A.dG(q)
p=J.v(r.a(t.h(o,3)),1)
o=J.v(r.a(t.h(o,0)),1)
if(typeof p!=="number")return p.a7()
if(typeof o!=="number")return A.dG(o)
o=Math.abs((s-q)*(p-o))===6}else o=s
else o=s
else o=s
else o=s}else o=s
else o=s
return o},
$S:0}
A.da.prototype={
$1(a){var t
u.j.a(a)
t=J.o(a)
return t.gi(a)===2&&t.t(a,new A.d3())},
$S:8}
A.d3.prototype={
$1(a){return A.u(a)&&a>=0&&a<=4},
$S:1}
A.dc.prototype={
$1(a){var t,s
u.P.a(a)
t=u.j
s=J.dZ(t.a(a.h(0,"cells")))
return J.V(t.a(a.h(0,"cells")))===3&&s.a===3&&s.a0([11,16,23])},
$S:0}
A.dd.prototype={
$1(a){var t,s,r,q
u.P.a(a)
t=u.j
s=t.a(a.h(0,"turns"))
r=J.o(s)
q=!1
if(r.gi(s)===2)if(r.t(s,new A.d9())){q=r.h(s,0)
r=r.h(s,1)
if(typeof q!=="number")return q.a7()
if(typeof r!=="number")return A.dG(r)
t=Math.abs(q-r)===2&&A.cb(t.a(a.h(0,"placed")),[!0,!0])}else t=q
else t=q
return t},
$S:0}
A.d9.prototype={
$1(a){return A.u(a)&&a>=0&&a<4},
$S:1}
A.df.prototype={
$1(a){var t,s,r,q,p,o,n="commands"
u.P.a(a)
t=u.j
if(J.V(t.a(a.h(0,n)))>32)return!1
for(t=J.a8(t.a(a.h(0,n))),s=u.s,r=0,q=0;t.l();){p=t.gm()
if(!B.a.v(A.a(["R","L","D","U"],s),p))return!1
o=J.Y(p)
if(o.B(p,"R"))++r
if(o.B(p,"L"))--r
if(o.B(p,"D"))++q
if(o.B(p,"U"))--q
o=!0
if(r>=0)if(r<=3)if(q>=0)if(q<=3)o=r===1&&q===1
if(o)return!1}return r===3&&q===3},
$S:0}
A.dg.prototype={
$1(a){u.P.a(a)
return A.cb(u.j.a(a.h(0,"body")),["R","D"])&&J.f(a.h(0,"repeat"),3)},
$S:0}
A.dh.prototype={
$1(a){var t,s
u.P.a(a)
t=u.j
s=J.cc(t.a(a.h(0,"stages")),u.S)
if(s.gi(0)===0||J.V(s.a)>6||s.J(s,new A.d7()))return!1
return A.cb(t.a(a.h(0,"result")),A.fs(s,A.a([4,1,3,2],u.t)))&&B.a.t($.fL(),new A.d8(s))},
$S:0}
A.d7.prototype={
$1(a){A.D(a)
return a<0||a>2},
$S:11}
A.d8.prototype={
$1(a){return A.cb(A.fs(this.a,u.M.a(a)),[1,2,3,4])},
$S:12}
A.di.prototype={
$1(a){var t
u.P.a(a)
t=u.j
return J.V(t.a(a.h(0,"edges")))===2&&J.dZ(t.a(a.h(0,"edges"))).a0(["0-1","2-3"])},
$S:0}
A.dj.prototype={
$1(a){return A.cb(u.j.a(u.P.a(a).h(0,"switches")),[!1,!0,!0])},
$S:0}
A.dk.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"rgb")),s=J.o(t)
return s.gi(t)===3&&s.t(t,new A.d6())&&A.af(s.h(t,0))>0.95&&A.af(s.h(t,1))>0.95&&A.af(s.h(t,2))<0.05},
$S:0}
A.d6.prototype={
$1(a){return typeof a=="number"&&a>=0&&a<=1},
$S:1}
A.dl.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"balls")),s=J.o(t)
return s.gi(t)===6&&s.M(t,new A.d4()).gi(0)===2&&s.M(t,new A.d5()).gi(0)===4},
$S:0}
A.d4.prototype={
$1(a){return J.f(a,"B")},
$S:1}
A.d5.prototype={
$1(a){return J.f(a,"R")},
$S:1}
A.dm.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"outcomes")),s=J.o(t)
return s.gi(t)===4&&s.H(t).a0(["SS","SN","NS","NN"])},
$S:0}
A.de.prototype={
$1(a){return J.f(u.P.a(a).h(0,"sectors"),3)},
$S:0}
A.dp.prototype={
$1(a){var t="position"
u.P.a(a)
return A.u(a.h(0,t))&&J.f(a.h(0,t),6)},
$S:0}
A.dq.prototype={
$1(a){u.P.a(a)
return J.f(a.h(0,"a"),!0)&&J.f(a.h(0,"b"),!1)},
$S:0}
A.dr.prototype={
$1(a){var t,s,r="outlier"
u.P.a(a)
t=!1
if(A.u(a.h(0,r))){s=a.h(0,r)
if(typeof s!=="number")return s.a5()
if(s>=10){t=a.h(0,r)
if(typeof t!=="number")return t.am()
t=t<=15}}return t},
$S:0}
A.M.prototype={}
A.r.prototype={
aD(a){var t,s
u.P.a(a)
try{t=this.y
t=t==null?null:t.$1(a)
if(t==null)t=new A.M(this.w.$1(a),B.b,B.b,"try-again")
return t}catch(s){return B.d}}}
A.cL.prototype={
$1(a){return A.aD(a)},
$S:3}
A.cX.prototype={
$1(a){return J.f(u.P.a(a).h(0,"pairs"),this.a)},
$S:0}
A.cT.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"painted")),s=J.o(t),r=this.a
return s.gi(t)===r&&s.H(t).a===r&&s.t(t,new A.cR())},
$S:0}
A.cR.prototype={
$1(a){return A.u(a)&&a>=0&&a<8},
$S:1}
A.cQ.prototype={
$1(a){var t,s
u.P.a(a)
t=u.j.a(a.h(0,"segments"))
s=J.o(t)
return s.gi(t)===3&&s.t(t,new A.cP())&&this.a.$1(a)},
$S:0}
A.cP.prototype={
$1(a){return A.u(a)&&a>=0&&a<=2},
$S:1}
A.cF.prototype={
$2(a,b){return A.D(a)+A.D(b)},
$S:7}
A.cG.prototype={
$1(a){return A.ef(u.P.a(a).h(0,"heights"),this.a)},
$S:0}
A.cW.prototype={
$1(a){var t,s,r,q,p=u.j,o=J.cc(p.a(u.P.a(a).h(0,"points")),p)
p=o.a
t=J.o(p)
if(t.gi(p)!==4||o.J(o,new A.cV()))return!1
s=o.$ti.y[1]
r=Math.abs(A.D(J.v(s.a(t.h(p,1)),0))-A.D(J.v(s.a(t.h(p,0)),0)))
q=Math.abs(A.D(J.v(s.a(t.h(p,3)),1))-A.D(J.v(s.a(t.h(p,0)),1)))
return J.f(J.v(s.a(t.h(p,0)),1),J.v(s.a(t.h(p,1)),1))&&J.f(J.v(s.a(t.h(p,1)),0),J.v(s.a(t.h(p,2)),0))&&J.f(J.v(s.a(t.h(p,2)),1),J.v(s.a(t.h(p,3)),1))&&J.f(J.v(s.a(t.h(p,3)),0),J.v(s.a(t.h(p,0)),0))&&r*q===this.a&&2*(r+q)===this.b},
$S:0}
A.cV.prototype={
$1(a){var t
u.j.a(a)
t=J.o(a)
return t.gi(a)!==2||t.J(a,new A.cU())},
$S:8}
A.cU.prototype={
$1(a){return!A.u(a)||a<0||a>4},
$S:1}
A.cY.prototype={
$1(a){var t,s,r,q,p,o,n,m,l=u.j.a(u.P.a(a).h(0,"commands")),k=J.o(l)
if(k.gu(l)||k.gi(l)>this.a)return!1
t=this.b
s=t==null
for(k=k.gn(l),r=!s,q=u.s,p=0,o=0;k.l();){n=k.gm()
if(!B.a.v(A.a(["R","L","D","U"],q),n))return!1
m=J.Y(n)
if(m.B(n,"R"))++p
if(m.B(n,"L"))--p
if(m.B(n,"D"))++o
if(m.B(n,"U"))--o
m=!0
if(p>=0)if(p<=3)if(o>=0)if(o<=3)m=p===1&&o===1
if(m)return!1
if(r&&p===t[0]&&o===t[1])s=!0}return p===3&&o===3&&s},
$S:0}
A.cN.prototype={
$1(a){return A.D(a)*100},
$S:13}
A.cO.prototype={
$1(a){var t,s,r,q=u.j.a(u.P.a(a).h(0,"rgb")),p=J.o(q)
if(p.gi(q)===3){t=J.av(3,u.y)
for(s=this.a,r=0;r<3;++r)t[r]=typeof p.h(q,r)=="number"&&A.af(p.h(q,r))>=0&&A.af(p.h(q,r))<=1&&Math.abs(A.af(p.h(q,r))-s[r])<0.05
p=B.a.t(t,new A.cM())}else p=!1
return p},
$S:0}
A.cM.prototype={
$1(a){return A.aD(a)},
$S:3}
A.cE.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"balls")),s=J.o(t)
return s.gi(t)===this.a&&s.t(t,new A.cC())&&s.M(t,new A.cD()).gi(0)===this.b},
$S:0}
A.cC.prototype={
$1(a){var t=J.Y(a)
return t.B(a,"B")||t.B(a,"R")},
$S:1}
A.cD.prototype={
$1(a){return J.f(a,"B")},
$S:1}
A.dB.prototype={
$1(a){return J.f(u.P.a(a).h(0,"blocks"),6)},
$S:0}
A.dC.prototype={
$1(a){return A.ef(u.P.a(a).h(0,"segments"),A.a([2,2,0],u.t))},
$S:0}
A.dD.prototype={
$1(a){return A.ef(u.P.a(a).h(0,"segments"),A.a([1,0,2],u.t))},
$S:0}
A.dE.prototype={
$1(a){var t=u.j.a(u.P.a(a).h(0,"segments")),s=J.Z(t)
return s.M(t,new A.dz()).gi(0)===1&&s.M(t,new A.dA()).gi(0)===2},
$S:0}
A.dz.prototype={
$1(a){return J.f(a,2)},
$S:1}
A.dA.prototype={
$1(a){return J.f(a,0)},
$S:1}
A.dw.prototype={
$1(a){return!A.u(a)||a<0||a>=8},
$S:1}
A.cS.prototype={
$1(a){return A.u(a)&&a>=0&&a<8},
$S:1}
A.cI.prototype={
$1(a){return A.aD(a)},
$S:3}
A.cZ.prototype={
$1(a){return u.X.a(a)},
$S:14}
A.d_.prototype={
$1(a){var t
u.A.a(a)
t=this.a
return a.a===t.h(0,"activity_id")&&a.Q===t.h(0,"content_version")},
$S:15}
A.dO.prototype={
$1(a){return A.dx("geography-globe-grid",u.P.a(a))},
$S:2}
A.dP.prototype={
$1(a){var t="latitude",s="longitude"
u.P.a(a)
return A.u(a.h(0,t))&&A.u(a.h(0,s))&&J.f(a.h(0,t),15)&&J.f(a.h(0,s),105)},
$S:0}
A.dQ.prototype={
$1(a){return A.dx("geography-rock-layers",u.P.a(a))},
$S:2}
A.dR.prototype={
$1(a){return A.fx(u.P.a(a).h(0,"layers"))},
$S:0}
A.dS.prototype={
$1(a){return A.dx("geometry-solid-volume",u.P.a(a))},
$S:2}
A.dT.prototype={
$1(a){u.P.a(a)
return A.ew(a)&&A.es(a)===12&&A.ft(a)===32},
$S:0}
A.dU.prototype={
$1(a){return A.dx("algebra-solid-relation",u.P.a(a))},
$S:2}
A.dV.prototype={
$1(a){u.P.a(a)
return A.ew(a)&&A.es(a)===16&&J.f(a.h(0,"width"),2*A.af(a.h(0,"height")))&&J.f(a.h(0,"depth"),a.h(0,"height"))},
$S:0}
A.dY.prototype={
$1(a){var t,s,r
A.a7(a)
t=this.a
s=!1
if(A.u(t.h(0,a))){r=t.h(0,a)
if(typeof r!=="number")return r.a5()
if(r>=1){t=t.h(0,a)
if(typeof t!=="number")return t.am()
t=t<=5}else t=s}else t=s
return t},
$S:16}
A.dX.prototype={
$1(a){return A.u(a)},
$S:1}
A.dy.prototype={
$1(a){return!A.u(a)||!B.a.v(B.N,a)},
$S:1};(function aliases(){var t=J.ac.prototype
t.an=t.k})();(function installTearOffs(){var t=hunkHelpers._instance_1i,s=hunkHelpers._static_1
t(J.A.prototype,"gT","v",4)
t(A.a6.prototype,"gT","v",4)
t(A.j.prototype,"gT","v",4)
s(A,"iB","hV",5)
t(A.c.prototype,"gT","v",4)
s(A,"iH","iD",2)
s(A,"iI","iE",2)
s(A,"iV","hS",0)
s(A,"j4","iq",0)
s(A,"iZ","hZ",0)
s(A,"j3","im",0)
s(A,"iY","hY",0)
s(A,"iX","hX",0)
s(A,"j_","ii",0)
s(A,"j2","il",0)
s(A,"j0","ij",0)
s(A,"j5","it",0)
s(A,"iW","hT",0)
s(A,"j1","ik",0)
s(A,"er","ir",17)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.w,null)
r(A.w,[A.e2,J.by,A.b9,J.ag,A.c,A.aI,A.z,A.a3,A.bc,A.aM,A.aK,A.K,A.aJ,A.cq,A.co,A.aa,A.P,A.ck,A.aY,A.aZ,A.aX,A.aR,A.c6,A.c0,A.bV,A.c8,A.W,A.c2,A.cw,A.az,A.c5,A.al,A.j,A.bt,A.bv,A.cu,A.ba,A.ce,A.ad,A.b5,A.aA,A.M,A.r])
r(J.by,[J.bA,J.aP,J.aT,J.aS,J.aU,J.aQ,J.ai])
r(J.aT,[J.ac,J.A,A.ax,A.b3])
r(J.ac,[J.bO,J.aB,J.ab])
s(J.bz,A.b9)
s(J.cf,J.A)
r(J.aQ,[J.aO,J.bB])
r(A.c,[A.a6,A.h,A.a5,A.aL,A.c_,A.c7])
r(A.a6,[A.ah,A.bo])
s(A.be,A.ah)
s(A.bd,A.bo)
s(A.a0,A.bd)
r(A.z,[A.bE,A.bb,A.bC,A.bY,A.bS,A.c1,A.aV,A.bq,A.a9,A.bZ,A.bX,A.bT,A.bu])
r(A.h,[A.a2,A.aj,A.b_,A.aW])
r(A.a2,[A.b0,A.c4])
s(A.G,A.aJ)
s(A.b6,A.bb)
r(A.aa,[A.bs,A.bW,A.dH,A.dJ,A.cB,A.cA,A.cK,A.d0,A.ds,A.dt,A.dv,A.dN,A.dM,A.d1,A.db,A.da,A.d3,A.dc,A.dd,A.d9,A.df,A.dg,A.dh,A.d7,A.d8,A.di,A.dj,A.dk,A.d6,A.dl,A.d4,A.d5,A.dm,A.de,A.dp,A.dq,A.dr,A.cL,A.cX,A.cT,A.cR,A.cQ,A.cP,A.cG,A.cW,A.cV,A.cU,A.cY,A.cN,A.cO,A.cM,A.cE,A.cC,A.cD,A.dB,A.dC,A.dD,A.dE,A.dz,A.dA,A.dw,A.cS,A.cI,A.cZ,A.d_,A.dO,A.dP,A.dQ,A.dR,A.dS,A.dT,A.dU,A.dV,A.dY,A.dX,A.dy])
r(A.bW,[A.bU,A.at])
r(A.P,[A.a1,A.c3])
r(A.bs,[A.cg,A.dI,A.cn,A.cv,A.du,A.cF])
r(A.b3,[A.bF,A.ay])
r(A.ay,[A.bf,A.bh])
s(A.bg,A.bf)
s(A.b1,A.bg)
s(A.bi,A.bh)
s(A.b2,A.bi)
r(A.b1,[A.bG,A.bH])
r(A.b2,[A.bI,A.bJ,A.bK,A.bL,A.bM,A.b4,A.bN])
s(A.bk,A.c1)
s(A.bj,A.az)
s(A.ak,A.bj)
s(A.bD,A.aV)
s(A.ch,A.bt)
r(A.bv,[A.cj,A.ci])
s(A.ct,A.cu)
r(A.a9,[A.b7,A.bx])
t(A.bo,A.j)
t(A.bf,A.j)
t(A.bg,A.K)
t(A.bh,A.j)
t(A.bi,A.K)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{b:"int",l:"double",ar:"num",m:"String",k:"bool",b5:"Null",i:"List",w:"Object",O:"Map",C:"JSObject"},mangledNames:{},types:["k(O<m,@>)","k(@)","M(O<m,@>)","k(k)","k(w?)","@(@)","~(w?,w?)","b(b,b)","k(i<@>)","@(@,m)","@(m)","k(b)","k(i<b>)","b(b)","i<r>(i<r>)","k(r)","k(m)","m(m)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti")}
A.hH(v.typeUniverse,JSON.parse('{"ab":"ac","bO":"ac","aB":"ac","jf":"ax","bA":{"k":[],"n":[]},"aP":{"n":[]},"aT":{"C":[]},"ac":{"C":[]},"A":{"i":["1"],"h":["1"],"C":[],"c":["1"]},"bz":{"b9":[]},"cf":{"A":["1"],"i":["1"],"h":["1"],"C":[],"c":["1"]},"ag":{"B":["1"]},"aQ":{"l":[],"ar":[]},"aO":{"l":[],"b":[],"ar":[],"n":[]},"bB":{"l":[],"ar":[],"n":[]},"ai":{"m":[],"cp":[],"n":[]},"a6":{"c":["2"]},"aI":{"B":["2"]},"ah":{"a6":["1","2"],"c":["2"],"c.E":"2"},"be":{"ah":["1","2"],"a6":["1","2"],"h":["2"],"c":["2"],"c.E":"2"},"bd":{"j":["2"],"i":["2"],"a6":["1","2"],"h":["2"],"c":["2"]},"a0":{"bd":["1","2"],"j":["2"],"i":["2"],"a6":["1","2"],"h":["2"],"c":["2"],"j.E":"2","c.E":"2"},"bE":{"z":[]},"h":{"c":["1"]},"a2":{"h":["1"],"c":["1"]},"a3":{"B":["1"]},"b0":{"a2":["2"],"h":["2"],"c":["2"],"c.E":"2","a2.E":"2"},"a5":{"c":["1"],"c.E":"1"},"bc":{"B":["1"]},"aL":{"c":["2"],"c.E":"2"},"aM":{"B":["2"]},"aK":{"B":["1"]},"aJ":{"O":["1","2"]},"G":{"aJ":["1","2"],"O":["1","2"]},"b6":{"z":[]},"bC":{"z":[]},"bY":{"z":[]},"aa":{"au":[]},"bs":{"au":[]},"bW":{"au":[]},"bU":{"au":[]},"at":{"au":[]},"bS":{"z":[]},"a1":{"P":["1","2"],"eN":["1","2"],"O":["1","2"],"P.K":"1","P.V":"2"},"aj":{"h":["1"],"c":["1"],"c.E":"1"},"aY":{"B":["1"]},"b_":{"h":["1"],"c":["1"],"c.E":"1"},"aZ":{"B":["1"]},"aW":{"h":["ad<1,2>"],"c":["ad<1,2>"],"c.E":"ad<1,2>"},"aX":{"B":["ad<1,2>"]},"aR":{"hj":[],"cp":[]},"c6":{"b8":[],"aw":[]},"c_":{"c":["b8"],"c.E":"b8"},"c0":{"B":["b8"]},"bV":{"aw":[]},"c7":{"c":["aw"],"c.E":"aw"},"c8":{"B":["aw"]},"ax":{"C":[],"n":[]},"b3":{"C":[]},"bF":{"C":[],"n":[]},"ay":{"N":["1"],"C":[]},"b1":{"j":["l"],"i":["l"],"N":["l"],"h":["l"],"C":[],"c":["l"],"K":["l"]},"b2":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"]},"bG":{"j":["l"],"i":["l"],"N":["l"],"h":["l"],"C":[],"c":["l"],"K":["l"],"n":[],"j.E":"l"},"bH":{"j":["l"],"i":["l"],"N":["l"],"h":["l"],"C":[],"c":["l"],"K":["l"],"n":[],"j.E":"l"},"bI":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"],"n":[],"j.E":"b"},"bJ":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"],"n":[],"j.E":"b"},"bK":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"],"n":[],"j.E":"b"},"bL":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"],"n":[],"j.E":"b"},"bM":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"],"n":[],"j.E":"b"},"b4":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"],"n":[],"j.E":"b"},"bN":{"j":["b"],"i":["b"],"N":["b"],"h":["b"],"C":[],"c":["b"],"K":["b"],"n":[],"j.E":"b"},"c1":{"z":[]},"bk":{"z":[]},"ak":{"az":["1"],"eO":["1"],"h":["1"],"c":["1"]},"al":{"B":["1"]},"P":{"O":["1","2"]},"az":{"h":["1"],"c":["1"]},"bj":{"az":["1"],"h":["1"],"c":["1"]},"c3":{"P":["m","@"],"O":["m","@"],"P.K":"m","P.V":"@"},"c4":{"a2":["m"],"h":["m"],"c":["m"],"c.E":"m","a2.E":"m"},"aV":{"z":[]},"bD":{"z":[]},"l":{"ar":[]},"b":{"ar":[]},"i":{"h":["1"],"c":["1"]},"b8":{"aw":[]},"m":{"cp":[]},"bq":{"z":[]},"bb":{"z":[]},"a9":{"z":[]},"b7":{"z":[]},"bx":{"z":[]},"bZ":{"z":[]},"bX":{"z":[]},"bT":{"z":[]},"bu":{"z":[]},"ba":{"z":[]},"aA":{"hl":[]},"h8":{"i":["b"],"h":["b"],"c":["b"]},"hp":{"i":["b"],"h":["b"],"c":["b"]},"ho":{"i":["b"],"h":["b"],"c":["b"]},"h6":{"i":["b"],"h":["b"],"c":["b"]},"hm":{"i":["b"],"h":["b"],"c":["b"]},"h7":{"i":["b"],"h":["b"],"c":["b"]},"hn":{"i":["b"],"h":["b"],"c":["b"]},"h4":{"i":["l"],"h":["l"],"c":["l"]},"h5":{"i":["l"],"h":["l"],"c":["l"]}}'))
A.hG(v.typeUniverse,JSON.parse('{"bo":2,"ay":1,"bj":1,"bt":2,"bv":2}'))
var u=(function rtii(){var t=A.bp
return{R:t("G<m,@>"),Q:t("h<@>"),C:t("z"),A:t("r"),Z:t("au"),U:t("c<@>"),J:t("A<r>"),p:t("A<i<b>>"),s:t("A<m>"),n:t("A<l>"),b:t("A<@>"),t:t("A<b>"),T:t("aP"),m:t("C"),L:t("ab"),D:t("N<@>"),X:t("i<r>"),j:t("i<@>"),M:t("i<b>"),P:t("O<m,@>"),f:t("O<@,@>"),a:t("b5"),K:t("w"),V:t("jg"),F:t("b8"),N:t("m"),k:t("n"),o:t("aB"),y:t("k"),i:t("l"),z:t("@"),S:t("b"),W:t("eJ<b5>?"),B:t("C?"),Y:t("i<@>?"),O:t("w?"),v:t("m?"),g:t("c5?"),u:t("k?"),I:t("l?"),w:t("b?"),x:t("ar?"),H:t("ar"),E:t("~(m,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.G=J.by.prototype
B.a=J.A.prototype
B.k=J.aO.prototype
B.H=J.aQ.prototype
B.e=J.ai.prototype
B.I=J.ab.prototype
B.J=J.aT.prototype
B.l=J.bO.prototype
B.h=J.aB.prototype
B.m=new A.aK(A.bp("aK<0&>"))
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

B.f=new A.ch()
B.b=t([],u.s)
B.d=new A.M(!1,B.b,B.b,"invalid-state")
B.K=new A.ci(null)
B.L=new A.cj(null)
B.N=t([10,20,30],u.t)
B.ad={}
B.c=new A.G(B.ad,[],u.R)
B.af={logic:0,math:1,science:2,data:3}
B.ac={blocks:0}
B.a0=new A.G(B.ac,[0],u.R)
B.B=new A.r("logic-balance","balanceBlocks",B.a0,A.iV(),null,1,B.c)
B.aj={pairs:0}
B.a_=new A.G(B.aj,[0],u.R)
B.w=new A.r("logic-remove","removeBothSides",B.a_,A.j4(),null,1,B.c)
B.am={turns:0}
B.a2=new A.G(B.am,[0],u.R)
B.F=new A.r("logic-gears","gearRatios",B.a2,A.iZ(),null,1,B.c)
B.Q=t([B.B,B.w,B.F],u.J)
B.ai={painted:0}
B.T=t([],u.b)
B.Z=new A.G(B.ai,[B.T],u.R)
B.az=t(["fractions.part-whole"],u.s)
B.z=new A.r("math-paint","fractionPaint",B.Z,A.j3(),A.iI(),1,B.c)
B.ae={folds:0}
B.a1=new A.G(B.ae,[0],u.R)
B.ay=t(["fractions.equal-parts"],u.s)
B.u=new A.r("math-fold","fractionFold",B.a1,A.iY(),null,1,B.c)
B.aa={baskets:0}
B.M=t([0,0,0],u.t)
B.X=new A.G(B.aa,[B.M],u.R)
B.C=new A.r("math-share","distributeObjects",B.X,A.iX(),null,1,B.c)
B.R=t([B.z,B.u,B.C],u.J)
B.a9={angle:0,launched:1}
B.a5=new A.G(B.a9,[20,!1],u.R)
B.v=new A.r("science-launch","launchAngle",B.a5,A.j_(),null,1,B.c)
B.al={segments:0}
B.W=t([-1,-1,-1],u.t)
B.a6=new A.G(B.al,[B.W],u.R)
B.E=new A.r("science-motion","motionTimeline",B.a6,A.j2(),null,1,B.c)
B.ak={position:0}
B.a7=new A.G(B.ak,[0],u.R)
B.D=new A.r("science-lever","leverTorque",B.a7,A.j0(),null,1,B.c)
B.U=t([B.v,B.E,B.D],u.J)
B.ah={order:0}
B.P=t([3,1,4,2],u.t)
B.a3=new A.G(B.ah,[B.P],u.R)
B.x=new A.r("data-sort","sortBars",B.a3,A.j5(),null,1,B.c)
B.ab={bins:0}
B.S=t([-1,-1,-1,-1,-1,-1],u.t)
B.a4=new A.G(B.ab,[B.S],u.R)
B.y=new A.r("data-bins","histogramBins",B.a4,A.iW(),null,1,B.c)
B.ag={heights:0}
B.O=t([2,4,6],u.t)
B.Y=new A.G(B.ag,[B.O],u.R)
B.A=new A.r("data-mean","redistributeMean",B.Y,A.j1(),null,1,B.c)
B.V=t([B.x,B.y,B.A],u.J)
B.a8=new A.G(B.af,[B.Q,B.R,B.U,B.V],A.bp("G<m,i<r>>"))
B.an=A.a_("jb")
B.ao=A.a_("jc")
B.ap=A.a_("h4")
B.aq=A.a_("h5")
B.ar=A.a_("h6")
B.as=A.a_("h7")
B.at=A.a_("h8")
B.au=A.a_("hm")
B.av=A.a_("hn")
B.aw=A.a_("ho")
B.ax=A.a_("hp")})();(function staticFields(){$.cs=null
$.S=A.a([],A.bp("A<w>"))
$.eP=null
$.eF=null
$.eE=null
$.fn=null
$.fj=null
$.fq=null
$.dn=null
$.dK=null
$.eo=null})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"je","fy",()=>A.dF("_$dart_dartClosure"))
t($,"jd","ex",()=>A.dF("_$dart_dartClosure_dartJSInterop"))
t($,"js","fK",()=>A.a([new J.bz()],A.bp("A<b9>")))
t($,"jh","fz",()=>A.a4(A.cr({
toString:function(){return"$receiver$"}})))
t($,"ji","fA",()=>A.a4(A.cr({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"jj","fB",()=>A.a4(A.cr(null)))
t($,"jk","fC",()=>A.a4(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"jn","fF",()=>A.a4(A.cr(void 0)))
t($,"jo","fG",()=>A.a4(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"jm","fE",()=>A.a4(A.eU(null)))
t($,"jl","fD",()=>A.a4(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"jq","fI",()=>A.a4(A.eU(void 0)))
t($,"jp","fH",()=>A.a4(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"jr","fJ",()=>{var s,r,q,p,o,n="algebra",m="geography",l="optimization",k="painting",j=u.N,i=u.X,h=A.cl(j,i)
for(j=A.hc(j,i),j.E(0,B.a8),j.E(0,$.ez()),j=j.gah().gn(0),i=u.A,s=u.J;j.l();){r=j.gm()
q=r.a
p=A.e5(r.b,i)
o=$.eA().h(0,q)
B.a.E(p,o==null?A.a([],s):o)
o=$.fN().h(0,q)
B.a.E(p,o==null?A.a([],s):o)
o=$.eB().h(0,q)
B.a.E(p,o==null?A.a([],s):o)
o=$.ey().h(0,q)
B.a.E(p,o==null?A.a([],s):o)
h.q(0,q,p)}j=$.eA()
s=j.h(0,n)
s.toString
i=A.e5(s,i)
s=$.eB()
q=s.h(0,n)
q.toString
B.a.E(i,q)
h.q(0,n,i)
s=s.h(0,m)
s.toString
h.q(0,m,s)
j=j.h(0,l)
j.toString
h.q(0,l,j)
j=$.ey()
s=j.h(0,"marxism")
s.toString
h.q(0,"marxism",s)
j=j.h(0,k)
j.toString
h.q(0,k,j)
return h})
t($,"jz","fP",()=>{var s,r,q,p,o,n,m=A.cl(u.N,u.X)
for(s=$.fJ().gah().gn(0),r=u.A;s.l();){q=s.gm()
p=q.a
o=A.e5(q.b,r)
n=$.fM().h(0,p)
if(n!=null)B.a.E(o,n)
m.q(0,p,o)}m.E(0,$.fO())
return m})
t($,"jy","fO",()=>{var s="matchPairs",r="N\u1ec1n t\u1ea3ng",q="V\u1eadn d\u1ee5ng",p="Th\u1eed th\xe1ch",o="categorySort",n="clozeBank",m=u.s,l=u.t,k=u.J
return A.d(["english",A.a([A.t("english-greetings","L\u1eddi ch\xe0o \u0111\u1ea7u ti\xean","Gh\xe9p c\xe2u ti\u1ebfng Anh v\u1edbi \xfd ngh\u0129a ph\xf9 h\u1ee3p.",A.a(["Hello!","Thank you.","Goodbye!"],m),A.a(["C\u1ea3m \u01a1n.","T\u1ea1m bi\u1ec7t!","Xin ch\xe0o!"],m),A.a([2,0,1],l),"Hello m\u1edf \u0111\u1ea7u cu\u1ed9c tr\xf2 chuy\u1ec7n; Thank you b\xe0y t\u1ecf l\u1eddi c\u1ea3m \u01a1n; Goodbye k\u1ebft th\xfac cu\u1ed9c g\u1eb7p.",s,r),A.fe("english-listen","Nghe v\xe0 t\xecm h\xe0nh \u0111\u1ed9ng","Please open the blue book.",A.a(["\u0110\xf3ng quy\u1ec3n s\xe1ch xanh.","M\u1edf quy\u1ec3n s\xe1ch xanh.","M\u1edf quy\u1ec3n s\xe1ch \u0111\u1ecf."],m),1,"Open l\xe0 m\u1edf; blue m\xf4 t\u1ea3 m\xe0u xanh c\u1ee7a book. Hi\u1ec3u c\u1ea3 \u0111\u1ed9ng t\u1eeb l\u1eabn t\xednh t\u1eeb gi\xfap l\xe0m \u0111\xfang y\xeau c\u1ea7u.",r),A.U("english-sentence","X\xe2y c\xe2u t\u1eeb nh\u1eefng m\u1ea3nh gh\xe9p","S\u1eafp x\u1ebfp th\xe0nh c\xe2u k\u1ec3: T\xf4i \u0111\u1ecdc s\xe1ch m\u1ed7i ng\xe0y.",A.a(["every day.","read","I","books"],m),A.a([2,1,3,0],l),"I read books every day: ch\u1ee7 ng\u1eef + \u0111\u1ed9ng t\u1eeb + t\xe2n ng\u1eef + c\u1ee5m th\u1eddi gian.",q),A.fi("english-introduce","N\xf3i l\u1eddi gi\u1edbi thi\u1ec7u","Luy\u1ec7n c\xe2u \u201cHello, my name is Alex.\u201d N\xf3i ho\u1eb7c nh\u1eadp c\xe2u; ch\xfa \xfd th\u1ee9 t\u1ef1 t\u1eeb.","Hello, my name is Alex.",A.a(["Hello my name is Alex"],m),"My name is d\xf9ng \u0111\u1ec3 gi\u1edbi thi\u1ec7u t\xean. M\xe1y ch\u1ec9 \u0111\u1ed1i chi\u1ebfu c\xe1c t\u1eeb nh\u1eadn d\u1ea1ng, kh\xf4ng \u0111\xe1nh gi\xe1 gi\u1ecdng hay m\u1ee9c \u0111\u1ed9 ph\xe1t \xe2m.",q),A.fe("english-inference","Nghe \u0111\u1ec3 suy lu\u1eadn","I used to walk to school, but now I take the bus because it is farther away.",A.a(["Hi\u1ec7n t\u1ea1i ng\u01b0\u1eddi n\xf3i lu\xf4n \u0111i b\u1ed9.","Ng\u01b0\u1eddi n\xf3i \u0111\u1ed5i sang xe bu\xfdt v\xec tr\u01b0\u1eddng xa h\u01a1n.","Ng\u01b0\u1eddi n\xf3i ch\u01b0a t\u1eebng \u0111i b\u1ed9."],m),1,"Used to n\xf3i v\u1ec1 th\xf3i quen c\u0169; but now ch\u1ec9 s\u1ef1 thay \u0111\u1ed5i; because gi\u1ea3i th\xedch l\xfd do.",p),A.fi("english-request","N\xf3i l\u1ecbch s\u1ef1 trong t\xecnh hu\u1ed1ng m\u1edbi","B\u1ea1n ch\u01b0a hi\u1ec3u l\u1eddi gi\u1ea3i. Luy\u1ec7n h\u1ecfi: \u201cCould you explain that again, please?\u201d","Could you explain that again, please?",A.a(["Could you explain that again please"],m),"Could you \u2026 please l\xe0 c\xe1ch y\xeau c\u1ea7u l\u1ecbch s\u1ef1. Again cho bi\u1ebft b\u1ea1n mu\u1ed1n nghe gi\u1ea3i th\xedch th\xeam l\u1ea7n n\u1eefa.",p)],k),"vietnamese",A.a([A.t("vietnamese-meaning","T\u1eeb ng\u1eef v\xe0 ng\u1eef c\u1ea3nh","Gh\xe9p t\u1eeb v\u1edbi ngh\u0129a trong c\xe2u n\xf3i h\u1eb1ng ng\xe0y.",A.a(["Quan s\xe1t","H\u1ee3p t\xe1c","Ki\xean tr\xec"],m),A.a(["C\xf9ng l\xe0m \u0111\u1ec3 \u0111\u1ea1t m\u1ee5c ti\xeau.","Ti\u1ebfp t\u1ee5c c\u1ed1 g\u1eafng d\xf9 g\u1eb7p kh\xf3.","Nh\xecn v\xe0 ghi nh\u1eadn chi ti\u1ebft."],m),A.a([2,0,1],l),"Hi\u1ec3u ch\xednh x\xe1c ngh\u0129a c\u1ee7a \u0111\u1ed9ng t\u1eeb gi\xfap bi\u1ebfn l\u1eddi h\u01b0\u1edbng d\u1eabn th\xe0nh h\xe0nh \u0111\u1ed9ng.",s,r),A.t("vietnamese-tone","Ch\u1ecdn l\u1eddi n\xf3i ph\xf9 h\u1ee3p","Ph\xe2n lo\u1ea1i l\u1eddi n\xf3i theo m\u1ee5c \u0111\xedch giao ti\u1ebfp.",A.a(["B\u1ea1n gi\xfap m\xecnh v\u1edbi \u0111\u01b0\u1ee3c kh\xf4ng?","C\u1ea3m \u01a1n b\u1ea1n \u0111\xe3 ch\u1edd.","M\xecnh xin l\u1ed7i v\xec \u0111\u1ebfn mu\u1ed9n."],m),A.a(["Nh\u1edd gi\xfap \u0111\u1ee1","C\u1ea3m \u01a1n","Xin l\u1ed7i"],m),A.a([0,1,2],l),"L\u1eddi nh\u1edd, c\u1ea3m \u01a1n v\xe0 xin l\u1ed7i c\xf3 m\u1ee5c \u0111\xedch kh\xe1c nhau; l\u1ecbch s\u1ef1 c\xf2n ph\u1ee5 thu\u1ed9c gi\u1ecdng \u0111i\u1ec7u v\xe0 t\xecnh hu\u1ed1ng.",o,r),A.U("vietnamese-story","K\u1ec3 chuy\u1ec7n c\xf3 m\u1ea1ch","S\u1eafp x\u1ebfp ba s\u1ef1 vi\u1ec7c \u0111\u1ec3 c\xe2u chuy\u1ec7n tr\u1ed3ng c\xe2y c\xf3 tr\xecnh t\u1ef1 h\u1ee3p l\xfd.",A.a(["H\u1ea1t n\u1ea3y m\u1ea7m.","Thu ho\u1ea1ch qu\u1ea3.","Gieo h\u1ea1t v\xe0 ch\u0103m s\xf3c."],m),A.a([2,0,1],l),"Tr\xecnh t\u1ef1 th\u1eddi gian gi\xfap ng\u01b0\u1eddi nghe theo \u0111\u01b0\u1ee3c di\u1ec5n bi\u1ebfn: gieo v\xe0 ch\u0103m \u2192 n\u1ea3y m\u1ea7m \u2192 c\xe2y tr\u01b0\u1edfng th\xe0nh cho qu\u1ea3.",q),A.t("vietnamese-connectors","N\u1ed1i \xfd cho r\xf5 ngh\u0129a","Ch\u1ecdn t\u1eeb n\u1ed1i \u0111\u1ec3 th\u1ec3 hi\u1ec7n \u0111\xfang quan h\u1ec7 trong hai c\xe2u.",A.a(["Tr\u1eddi m\u01b0a, ___ \u0111\u01b0\u1eddng \u01b0\u1edbt.","___ tr\u1eddi m\u01b0a, ch\xfang em v\u1eabn \u0111\u1ebfn \u0111\xfang gi\u1edd."],m),A.a(["n\xean","M\u1eb7c d\xf9","ho\u1eb7c"],m),A.a([0,1],l),"N\xean di\u1ec5n t\u1ea3 h\u1ec7 qu\u1ea3; m\u1eb7c d\xf9 m\u1edf \u0111\u1ea7u quan h\u1ec7 nh\u01b0\u1ee3ng b\u1ed9, \u0111i\u1ec1u x\u1ea3y ra tr\xe1i v\u1edbi k\u1ef3 v\u1ecdng.",n,r),A.L("vietnamese-argument","L\u1eadp lu\u1eadn b\u1eb1ng b\u1eb1ng ch\u1ee9ng","K\u1ebft lu\u1eadn: \u201cL\u1edbp n\xean gi\u1eef g\xf3c \u0111\u1ecdc s\xe1ch.\u201d Ch\u1ecdn c\xe1c d\u1eef ki\u1ec7n tr\u1ef1c ti\u1ebfp h\u1ed7 tr\u1ee3 \xedch l\u1ee3i c\u1ee7a g\xf3c \u0111\u1ecdc.",A.a(["Nh\u1eadt k\xfd cho th\u1ea5y 18/25 b\u1ea1n m\u01b0\u1ee3n s\xe1ch tu\u1ea7n n\xe0y.","M\u1ed9t b\u1ea1n n\xf3i: m\u1ecdi l\u1edbp tr\xean \u0111\u1eddi \u0111\u1ec1u th\xedch s\xe1ch.","Kh\u1ea3o s\xe1t l\u1edbp: 20/25 b\u1ea1n mu\u1ed1n ti\u1ebfp t\u1ee5c d\xf9ng g\xf3c \u0111\u1ecdc.","T\u01b0\u1eddng l\u1edbp \u0111\u01b0\u1ee3c s\u01a1n m\xe0u xanh."],m),A.a([0,2],l),"S\u1ed1 l\u01b0\u1ee3t m\u01b0\u1ee3n v\xe0 kh\u1ea3o s\xe1t \u0111\xfang \u0111\u1ed1i t\u01b0\u1ee3ng h\u1ed7 tr\u1ee3 l\u1eadp lu\u1eadn; kh\u1eb3ng \u0111\u1ecbnh tuy\u1ec7t \u0111\u1ed1i v\xe0 m\xe0u t\u01b0\u1eddng kh\xf4ng ch\u1ee9ng minh nhu c\u1ea7u."),A.U("vietnamese-revise","Bi\xean t\u1eadp m\u1ed9t th\xf4ng \u0111i\u1ec7p","S\u1eafp x\u1ebfp quy tr\xecnh vi\u1ebft l\u1eddi \u0111\u1ec1 ngh\u1ecb c\xf3 tr\xe1ch nhi\u1ec7m.",A.a(["Ki\u1ec3m tra gi\u1ecdng \u0111i\u1ec7u v\xe0 l\u1ed7i di\u1ec5n \u0111\u1ea1t.","X\xe1c \u0111\u1ecbnh ng\u01b0\u1eddi \u0111\u1ecdc v\xe0 m\u1ee5c \u0111\xedch.","Vi\u1ebft \u0111\u1ec1 ngh\u1ecb k\xe8m l\xfd do c\u1ee5 th\u1ec3.","G\u1eedi sau khi \u0111\u1ecdc l\u1ea1i."],m),A.a([1,2,0,3],l),"X\xe1c \u0111\u1ecbnh ng\u01b0\u1eddi \u0111\u1ecdc \u2192 vi\u1ebft c\xf3 l\xfd do \u2192 bi\xean t\u1eadp \u2192 g\u1eedi gi\xfap th\xf4ng \u0111i\u1ec7p r\xf5 r\xe0ng v\xe0 t\xf4n tr\u1ecdng.",p)],k),"biology",A.a([A.t("biology-parts","C\xe2y s\u1ed1ng b\u1eb1ng nh\u1eefng b\u1ed9 ph\u1eadn n\xe0o?","Gh\xe9p b\u1ed9 ph\u1eadn c\xe2y v\u1edbi m\u1ed9t ch\u1ee9c n\u0103ng ch\xednh.",A.a(["R\u1ec5","L\xe1","Th\xe2n"],m),A.a(["N\xe2ng \u0111\u1ee1 v\xe0 v\u1eadn chuy\u1ec3n.","H\u1ea5p th\u1ee5 n\u01b0\u1edbc v\xe0 ch\u1ea5t kho\xe1ng.","Quang h\u1ee3p khi c\xf3 \xe1nh s\xe1ng."],m),A.a([1,2,0],l),"C\xe1c b\u1ed9 ph\u1eadn ph\u1ed1i h\u1ee3p: r\u1ec5 h\u1ea5p th\u1ee5, th\xe2n n\xe2ng \u0111\u1ee1 v\xe0 v\u1eadn chuy\u1ec3n, l\xe1 quang h\u1ee3p.",s,r),A.t("biology-food","Vai tr\xf2 trong h\u1ec7 sinh th\xe1i","Ph\xe2n lo\u1ea1i theo vai tr\xf2 trong chu\u1ed7i th\u1ee9c \u0103n n\xe0y.",A.a(["C\u1ecf","Th\u1ecf","N\u1ea5m ph\xe2n gi\u1ea3i l\xe1 r\u1ee5ng"],m),A.a(["Sinh v\u1eadt s\u1ea3n xu\u1ea5t","Sinh v\u1eadt ti\xeau th\u1ee5","Sinh v\u1eadt ph\xe2n gi\u1ea3i"],m),A.a([0,1,2],l),"C\u1ecf t\u1ea1o ch\u1ea5t h\u1eefu c\u01a1; th\u1ecf ti\xeau th\u1ee5; n\u1ea5m ph\xe2n gi\u1ea3i v\u1eadt ch\u1ea5t. M\u1ed9t h\u1ec7 sinh th\xe1i c\u1ea7n nhi\u1ec1u vai tr\xf2.",o,r),A.U("biology-cycle","Theo d\u1ea5u v\xf2ng \u0111\u1eddi","B\u1eaft \u0111\u1ea7u t\u1eeb h\u1ea1t, s\u1eafp x\u1ebfp v\xf2ng \u0111\u1eddi c\xe2y \u0111\u1eadu trong \u0111i\u1ec1u ki\u1ec7n ph\xf9 h\u1ee3p.",A.a(["C\xe2y ra hoa.","H\u1ea1t n\u1ea3y m\u1ea7m.","Qu\u1ea3 c\xf3 h\u1ea1t m\u1edbi.","C\xe2y non ph\xe1t tri\u1ec3n."],m),A.a([1,3,0,2],l),"N\u1ea3y m\u1ea7m \u2192 c\xe2y non \u2192 c\xe2y ra hoa \u2192 qu\u1ea3 v\xe0 h\u1ea1t m\u1edbi. Kh\xf4ng ph\u1ea3i m\u1ecdi h\u1ea1t \u0111\u1ec1u s\u1ed1ng s\xf3t trong t\u1ef1 nhi\xean.",q),A.t("biology-photosynthesis","Ho\xe0n thi\u1ec7n m\xf4 h\xecnh quang h\u1ee3p","\u0110i\u1ec1n t\xean ch\u1ea5t v\xe0o m\xf4 h\xecnh gi\u1ea3n l\u01b0\u1ee3c.",A.a(["C\xe2y h\u1ea5p th\u1ee5 kh\xed ___ \u0111\u1ec3 t\u1ea1o ch\u1ea5t h\u1eefu c\u01a1.","Quang h\u1ee3p gi\u1ea3i ph\xf3ng kh\xed ___."],m),A.a(["oxygen","carbon dioxide","nitrogen"],m),A.a([1,0],l),"Trong quang h\u1ee3p, c\xe2y d\xf9ng carbon dioxide v\xe0 n\u01b0\u1edbc v\u1edbi n\u0103ng l\u01b0\u1ee3ng \xe1nh s\xe1ng \u0111\u1ec3 t\u1ea1o ch\u1ea5t h\u1eefu c\u01a1, gi\u1ea3i ph\xf3ng oxygen.",n,r),A.eh("biology-growth","Ph\xf2ng th\xed nghi\u1ec7m hai y\u1ebfu t\u1ed1","\u0110\xe2y l\xe0 m\xf4 h\xecnh \u0111i\u1ec3m t\xe0i nguy\xean, kh\xf4ng d\u1ef1 b\xe1o t\u1ed1c \u0111\u1ed9 sinh tr\u01b0\u1edfng th\u1eadt c\u1ee7a c\xe2y.","\xc1nh s\xe1ng","N\u01b0\u1edbc",6,"C\xe1c c\u1eb7p 2 \xd7 3 v\xe0 3 \xd7 2 \u0111\u1ec1u t\u1ea1o 6 \u0111i\u1ec3m trong m\xf4 h\xecnh. C\xe2y th\u1eadt c\xf2n ph\u1ee5 thu\u1ed9c nhi\u1ec7t \u0111\u1ed9, dinh d\u01b0\u1ee1ng v\xe0 gi\u1edbi h\u1ea1n sinh h\u1ecdc."),A.L("biology-control","Thi\u1ebft k\u1ebf th\xed nghi\u1ec7m c\xf4ng b\u1eb1ng","\u0110\u1ec3 ki\u1ec3m tra t\xe1c \u0111\u1ed9ng c\u1ee7a \xe1nh s\xe1ng l\xean c\xe2y c\xf9ng lo\xe0i, ch\u1ecdn c\xe1ch thi\u1ebft k\u1ebf gi\xfap t\xe1ch ri\xeang y\u1ebfu t\u1ed1 \xe1nh s\xe1ng.",A.a(["Gi\u1eef gi\u1ed1ng, \u0111\u1ea5t v\xe0 l\u01b0\u1ee3ng n\u01b0\u1edbc t\u01b0\u01a1ng \u0111\u01b0\u01a1ng.","\u0110\u1ed5i c\u1ea3 \xe1nh s\xe1ng l\u1eabn lo\u1ea1i \u0111\u1ea5t.","D\xf9ng nhi\u1ec1u c\xe2y cho m\u1ed7i nh\xf3m.","Ch\u1ec9 \u0111o m\u1ed9t c\xe2y kh\u1ecfe nh\u1ea5t sau khi bi\u1ebft k\u1ebft qu\u1ea3."],m),A.a([0,2],l),"Ki\u1ec3m so\xe1t c\xe1c y\u1ebfu t\u1ed1 kh\xe1c v\xe0 l\u1eb7p m\u1eabu gi\xfap gi\u1ea3m nhi\u1ec5u. Ch\u1ecdn m\u1eabu sau khi bi\u1ebft k\u1ebft qu\u1ea3 t\u1ea1o thi\xean l\u1ec7ch.")],k),"chemistry",A.a([A.t("chemistry-states","V\u1eadt ch\u1ea5t quanh ta","Ph\xe2n lo\u1ea1i \u1edf \u0111i\u1ec1u ki\u1ec7n th\u01b0\u1eddng \u0111\u01b0\u1ee3c m\xf4 t\u1ea3.",A.a(["Vi\xean n\u01b0\u1edbc \u0111\xe1 \u1edf \u22125\xb0C","N\u01b0\u1edbc trong c\u1ed1c \u1edf 25\xb0C","H\u01a1i n\u01b0\u1edbc"],m),A.a(["R\u1eafn","L\u1ecfng","Kh\xed"],m),A.a([0,1,2],l),"C\xf9ng m\u1ed9t ch\u1ea5t c\xf3 th\u1ec3 \u1edf nhi\u1ec1u th\u1ec3 t\xf9y nhi\u1ec7t \u0111\u1ed9 v\xe0 \xe1p su\u1ea5t. H\u01a1i n\u01b0\u1edbc l\xe0 kh\xed, kh\xf4ng ph\u1ea3i c\xe1c gi\u1ecdt s\u01b0\u01a1ng nh\xecn th\u1ea5y.",o,r),A.t("chemistry-tools","D\u1ee5ng c\u1ee5 v\xe0 ch\u1ee9c n\u0103ng","Gh\xe9p d\u1ee5ng c\u1ee5 v\u1edbi ch\u1ee9c n\u0103ng, ch\u1ec9 l\xe0m th\xed nghi\u1ec7m trong app.",A.a(["Nhi\u1ec7t k\u1ebf","C\xe2n","\u1ed0ng \u0111ong"],m),A.a(["\u0110o kh\u1ed1i l\u01b0\u1ee3ng","\u0110o th\u1ec3 t\xedch ch\u1ea5t l\u1ecfng","\u0110o nhi\u1ec7t \u0111\u1ed9"],m),A.a([2,0,1],l),"Ch\u1ecdn \u0111\xfang d\u1ee5ng c\u1ee5 v\xe0 \u0111\u01a1n v\u1ecb tr\u01b0\u1edbc khi \u0111o gi\xfap tr\xe1nh nh\u1ea7m kh\u1ed1i l\u01b0\u1ee3ng, th\u1ec3 t\xedch v\xe0 nhi\u1ec7t \u0111\u1ed9.",s,r),A.U("chemistry-water","\u0110i qua c\xe1c th\u1ec3","B\u1eaft \u0111\u1ea7u t\u1eeb n\u01b0\u1edbc \u0111\xe1, s\u1eafp x\u1ebfp qu\xe1 tr\xecnh khi c\u1ea5p nhi\u1ec7t li\xean t\u1ee5c \u1edf \xe1p su\u1ea5t th\u01b0\u1eddng.",A.a(["N\u01b0\u1edbc l\u1ecfng n\xf3ng l\xean.","N\u01b0\u1edbc \u0111\xe1 nh\u1eadn nhi\u1ec7t v\xe0 n\xf3ng ch\u1ea3y.","N\u01b0\u1edbc s\xf4i, chuy\u1ec3n d\u1ea7n th\xe0nh h\u01a1i."],m),A.a([1,0,2],l),"N\xf3ng ch\u1ea3y v\xe0 s\xf4i l\xe0 chuy\u1ec3n th\u1ec3; nhi\u1ec7t \u0111\u1ed9 kh\xf4ng t\u0103ng li\xean t\u1ee5c trong su\u1ed1t qu\xe1 tr\xecnh chuy\u1ec3n th\u1ec3 c\u1ee7a ch\u1ea5t tinh khi\u1ebft.",q),A.t("chemistry-atoms","\u0110\u1ebfm nguy\xean t\u1eed trong ph\xe2n t\u1eed","\u0110i\u1ec1n s\u1ed1 nguy\xean t\u1eed cho m\u1ed7i c\xf4ng th\u1ee9c.",A.a(["S\u1ed1 H trong H\u2082O","S\u1ed1 O trong CO\u2082","T\u1ed5ng nguy\xean t\u1eed trong H\u2082O"],m),A.a(["1","2","3"],m),A.a([1,1,2],l),"Ch\u1ec9 s\u1ed1 d\u01b0\u1edbi thu\u1ed9c nguy\xean t\u1ed1 ngay tr\u01b0\u1edbc n\xf3. H\u2082O c\xf3 2 H v\xe0 1 O; CO\u2082 c\xf3 1 C v\xe0 2 O.",n,r),A.c9("chemistry-conservation","B\u1ea3o to\xe0n trong m\xf4 h\xecnh h\u1ea1t","Chia 10 h\u1ea1t m\xf4 ph\u1ecfng v\xe0o ba h\u1ed9p; kh\xf4ng t\u1ea1o th\xeam hay l\xe0m m\u1ea5t h\u1ea1t.",A.a(["H\u1ed9p A","H\u1ed9p B","H\u1ed9p C"],m),A.a([2,3,1],l),"C\xe1c c\xe1ch ph\xe2n chia c\xf3 th\u1ec3 kh\xe1c nhau nh\u01b0ng t\u1ed5ng lu\xf4n l\xe0 10. \u0110\xe2y l\xe0 m\xf4 h\xecnh \u0111\u1ebfm h\u1ea1t, kh\xf4ng ph\u1ea3i m\xf4 t\u1ea3 m\u1ed9t ph\u1ea3n \u1ee9ng h\xf3a h\u1ecdc c\u1ee5 th\u1ec3."),A.L("chemistry-claim","Quan s\xe1t hay k\u1ebft lu\u1eadn v\u1ed9i?","M\u1ed9t c\u1ed1c c\xf3 b\u1ecdt khi khu\u1ea5y. Ch\u1ecdn c\xe1c nh\u1eadn \u0111\u1ecbnh khoa h\u1ecdc h\u1ee3p l\xfd.",A.a(["B\u1ecdt c\xf3 th\u1ec3 l\xe0 kh\xed tho\xe1t ra ho\u1eb7c kh\xf4ng kh\xed b\u1ecb cu\u1ed1n v\xe0o.","Ch\u1ec9 th\u1ea5y b\u1ecdt \u0111\xe3 \u0111\u1ee7 kh\u1eb3ng \u0111\u1ecbnh t\u1ea1o ch\u1ea5t m\u1edbi.","C\u1ea7n th\xeam d\u1eef ki\u1ec7n v\u1ec1 ch\u1ea5t ban \u0111\u1ea7u v\xe0 s\u1ea3n ph\u1ea9m.","M\u1ecdi bi\u1ebfn \u0111\u1ed5i \u0111\u1ec1u kh\xf4ng th\u1ec3 \u0111\u1ea3o ng\u01b0\u1ee3c."],m),A.a([0,2],l),"M\u1ed9t d\u1ea5u hi\u1ec7u ri\xeang l\u1ebb ch\u01b0a lu\xf4n ch\u1ee9ng minh ph\u1ea3n \u1ee9ng. C\u1ea7n ki\u1ec3m tra gi\u1ea3 thuy\u1ebft thay th\u1ebf v\xe0 \u0111\u1eb7c t\xednh ch\u1ea5t.")],k),"astronomy",A.a([A.t("astronomy-objects","Nh\u1eadn di\u1ec7n b\u1ea7u tr\u1eddi","Gh\xe9p thi\xean th\u1ec3 v\u1edbi m\xf4 t\u1ea3 ph\xf9 h\u1ee3p.",A.a(["M\u1eb7t Tr\u1eddi","Tr\xe1i \u0110\u1ea5t","M\u1eb7t Tr\u0103ng"],m),A.a(["V\u1ec7 tinh t\u1ef1 nhi\xean c\u1ee7a Tr\xe1i \u0110\u1ea5t","Ng\xf4i sao","H\xe0nh tinh"],m),A.a([1,2,0],l),"M\u1eb7t Tr\u1eddi l\xe0 sao; Tr\xe1i \u0110\u1ea5t l\xe0 h\xe0nh tinh; M\u1eb7t Tr\u0103ng l\xe0 v\u1ec7 tinh t\u1ef1 nhi\xean. \xc1nh s\xe1ng M\u1eb7t Tr\u0103ng ch\u1ee7 y\u1ebfu l\xe0 \xe1nh s\xe1ng M\u1eb7t Tr\u1eddi ph\u1ea3n x\u1ea1.",s,r),A.U("astronomy-scale","T\u1eeb g\u1ea7n \u0111\u1ebfn xa","S\u1eafp x\u1ebfp kho\u1ea3ng c\xe1ch \u0111i\u1ec3n h\xecnh t\xednh t\u1eeb Tr\xe1i \u0110\u1ea5t, t\u1eeb g\u1ea7n \u0111\u1ebfn xa.",A.a(["M\u1eb7t Tr\u1eddi","Ng\xf4i sao g\u1ea7n nh\u1ea5t ngo\xe0i M\u1eb7t Tr\u1eddi","M\u1eb7t Tr\u0103ng"],m),A.a([2,0,1],l),"M\u1eb7t Tr\u0103ng g\u1ea7n h\u01a1n M\u1eb7t Tr\u1eddi r\u1ea5t nhi\u1ec1u; c\xe1c sao kh\xe1c \u1edf xa h\u01a1n M\u1eb7t Tr\u1eddi nhi\u1ec1u b\u1eadc \u0111\u1ed9 l\u1edbn.",r),A.t("astronomy-motion","Chuy\u1ec3n \u0111\u1ed9ng v\xe0 hi\u1ec7n t\u01b0\u1ee3ng","Gh\xe9p chuy\u1ec3n \u0111\u1ed9ng ho\u1eb7c \u0111\u1eb7c \u0111i\u1ec3m v\u1edbi h\u1ec7 qu\u1ea3 ch\xednh.",A.a(["Tr\xe1i \u0110\u1ea5t t\u1ef1 quay","Tr\xe1i \u0110\u1ea5t quay quanh M\u1eb7t Tr\u1eddi","Tr\u1ee5c nghi\xeang v\xe0 qu\u1ef9 \u0111\u1ea1o quanh M\u1eb7t Tr\u1eddi"],m),A.a(["M\u1ed9t n\u0103m","Ng\xe0y v\xe0 \u0111\xeam","Chu k\u1ef3 c\xe1c m\xf9a"],m),A.a([1,0,2],l),"Ng\xe0y \u0111\xeam do t\u1ef1 quay; n\u0103m do chu k\u1ef3 qu\u1ef9 \u0111\u1ea1o; c\xe1c m\xf9a ch\u1ee7 y\u1ebfu do tr\u1ee5c nghi\xeang l\xe0m thay \u0111\u1ed5i g\xf3c chi\u1ebfu v\xe0 \u0111\u1ed9 d\xe0i ng\xe0y.",s,q),A.t("astronomy-moon","V\xec sao M\u1eb7t Tr\u0103ng \u0111\u1ed5i h\xecnh?","Ho\xe0n thi\u1ec7n l\u1eddi gi\u1ea3i th\xedch pha M\u1eb7t Tr\u0103ng.",A.a(["M\u1eb7t Tr\u0103ng \u0111\u01b0\u1ee3c chi\u1ebfu s\xe1ng b\u1edfi ___.","Ta nh\xecn th\u1ea5y ph\u1ea7n s\xe1ng kh\xe1c nhau khi v\u1ecb tr\xed ___ thay \u0111\u1ed5i."],m),A.a(["M\u1eb7t Tr\u1eddi","ba thi\xean th\u1ec3","b\xf3ng Tr\xe1i \u0110\u1ea5t m\u1ed7i \u0111\xeam"],m),A.a([0,1],l),"Pha M\u1eb7t Tr\u0103ng do h\xecnh h\u1ecdc nh\xecn ph\u1ea7n s\xe1ng. B\xf3ng Tr\xe1i \u0110\u1ea5t g\xe2y nguy\u1ec7t th\u1ef1c, kh\xf4ng ph\u1ea3i c\xe1c pha th\u01b0\u1eddng ng\xe0y.",n,r),A.c9("astronomy-mission","Thi\u1ebft k\u1ebf nhi\u1ec7m v\u1ee5 th\xe1m hi\u1ec3m","Trong tr\xf2 ch\u01a1i nhi\u1ec7m v\u1ee5, chia 10 \u0111\u01a1n v\u1ecb t\u1ea3i tr\u1ecdng; \u0111\xe2y l\xe0 r\xe0ng bu\u1ed9c gi\u1ea3 l\u1eadp.",A.a(["Thi\u1ebft b\u1ecb khoa h\u1ecdc","N\u0103ng l\u01b0\u1ee3ng","Li\xean l\u1ea1c"],m),A.a([3,3,2],l),"Nhi\u1ec7m v\u1ee5 c\xf3 nhi\u1ec1u ph\u01b0\u01a1ng \xe1n kh\u1ea3 thi. T\u1ed1i \u01b0u m\u1ed9t m\u1ee5c m\xe0 b\u1ecf n\u0103ng l\u01b0\u1ee3ng ho\u1eb7c li\xean l\u1ea1c c\xf3 th\u1ec3 l\xe0m c\u1ea3 h\u1ec7 th\u1ed1ng th\u1ea5t b\u1ea1i."),A.L("astronomy-seasons","Gi\u1ea3i th\xedch m\xf9a b\u1eb1ng b\u1eb1ng ch\u1ee9ng","Ch\u1ecdn d\u1eef ki\u1ec7n h\u1ed7 tr\u1ee3 m\xf4 h\xecnh m\xf9a do tr\u1ee5c nghi\xeang thay v\xec ch\u1ec9 do kho\u1ea3ng c\xe1ch \u0111\u1ebfn M\u1eb7t Tr\u1eddi.",A.a(["Hai b\xe1n c\u1ea7u c\xf3 c\xe1c m\xf9a \u0111\u1ed1i l\u1eadp.","\u0110\u1ed9 d\xe0i ban ng\xe0y thay \u0111\u1ed5i theo m\xf9a \u1edf nhi\u1ec1u v\u0129 \u0111\u1ed9.","M\xf9a h\xe8 v\xec Tr\xe1i \u0110\u1ea5t \u1edf g\u1ea7n M\u1eb7t Tr\u1eddi nh\u1ea5t t\u1ea1i m\u1ecdi n\u01a1i.","M\u1eb7t Tr\u1eddi t\u1ef1 t\u1eaft v\xe0o m\xf9a \u0111\xf4ng."],m),A.a([0,1],l),"M\xf9a \u0111\u1ed1i l\u1eadp gi\u1eefa hai b\xe1n c\u1ea7u v\xe0 \u0111\u1ed9 d\xe0i ng\xe0y thay \u0111\u1ed5i ph\xf9 h\u1ee3p m\xf4 h\xecnh tr\u1ee5c nghi\xeang.")],k),"finance",A.a([A.t("finance-needs","C\u1ea7n hay mu\u1ed1n trong t\xecnh hu\u1ed1ng n\xe0y?","Gia \u0111\xecnh \u0111\xe3 c\xf3 \u0111\u1ee7 \u0111\u1ed3 ch\u01a1i; ph\xe2n lo\u1ea1i c\xe1c kho\u1ea3n sau trong t\xecnh hu\u1ed1ng \u0111i h\u1ecdc.",A.a(["N\u01b0\u1edbc u\u1ed1ng an to\xe0n","\u0110\u1ed3 ch\u01a1i phi\xean b\u1ea3n m\u1edbi","V\u1edf \u0111\u1ec3 h\u1ecdc khi \u0111\xe3 h\u1ebft"],m),A.a(["Nhu c\u1ea7u thi\u1ebft y\u1ebfu","Mong mu\u1ed1n th\xeam"],m),A.a([0,1,0],l),"Nhu c\u1ea7u v\xe0 mong mu\u1ed1n ph\u1ee5 thu\u1ed9c ho\xe0n c\u1ea3nh. \u1ede t\xecnh hu\u1ed1ng n\xe0y n\u01b0\u1edbc v\xe0 v\u1edf c\u1ea7n cho sinh ho\u1ea1t, h\u1ecdc t\u1eadp.",o,r),A.t("finance-terms","Ng\xf4n ng\u1eef c\u1ee7a ng\xe2n s\xe1ch","Gh\xe9p kh\xe1i ni\u1ec7m v\u1edbi \xfd ngh\u0129a.",A.a(["Thu nh\u1eadp","Chi ti\xeau","Ti\u1ebft ki\u1ec7m"],m),A.a(["Ph\u1ea7n gi\u1eef l\u1ea1i cho m\u1ee5c ti\xeau sau","Kho\u1ea3n nh\u1eadn \u0111\u01b0\u1ee3c","Kho\u1ea3n d\xf9ng \u0111\u1ec3 mua ho\u1eb7c thanh to\xe1n"],m),A.a([1,2,0],l),"Ng\xe2n s\xe1ch theo d\xf5i kho\u1ea3n v\xe0o, kho\u1ea3n ra v\xe0 ph\u1ea7n gi\u1eef l\u1ea1i, kh\xf4ng ch\u1ec9 s\u1ed1 ti\u1ec1n \u0111ang c\xf3.",s,r),A.U("finance-plan","T\u1eeb m\u1ee5c ti\xeau \u0111\u1ebfn h\xe0nh \u0111\u1ed9ng","S\u1eafp x\u1ebfp quy tr\xecnh d\xe0nh ti\u1ec1n cho m\u1ed9t cu\u1ed1n s\xe1ch.",A.a(["Theo d\xf5i v\xe0 \u0111i\u1ec1u ch\u1ec9nh m\u1ed7i tu\u1ea7n.","X\xe1c \u0111\u1ecbnh gi\xe1 s\xe1ch v\xe0 th\u1eddi h\u1ea1n.","T\xednh s\u1ed1 c\u1ea7n \u0111\u1ec3 d\xe0nh m\u1ed7i tu\u1ea7n."],m),A.a([1,2,0],l),"M\u1ee5c ti\xeau c\u1ee5 th\u1ec3 \u2192 k\u1ebf ho\u1ea1ch theo th\u1eddi gian \u2192 theo d\xf5i th\u1ef1c t\u1ebf. \u0110i\u1ec1u ch\u1ec9nh k\u1ebf ho\u1ea1ch khi \u0111i\u1ec1u ki\u1ec7n thay \u0111\u1ed5i.",q),A.t("finance-change","T\xednh ph\u1ea7n c\xf2n l\u1ea1i","Trong c\u1eeda h\xe0ng gi\u1ea3 l\u1eadp, m\u1ed7i \u0111\u01a1n v\u1ecb l\xe0 m\u1ed9t \u0111i\u1ec3m tr\xf2 ch\u01a1i.",A.a(["C\xf3 10 \u0111i\u1ec3m, d\xf9ng 4, c\xf2n ___.","Mu\u1ed1n 8 \u0111i\u1ec3m, \u0111ang c\xf3 5, c\u1ea7n th\xeam ___."],m),A.a(["3","6","14"],m),A.a([1,0],l),"Theo d\xf5i s\u1ed1 d\u01b0 b\u1eb1ng ph\xe9p tr\u1eeb v\xe0 kho\u1ea3ng thi\u1ebfu gi\xfap tr\xe1nh chi qu\xe1 ngu\u1ed3n l\u1ef1c.",n,r),A.c9("finance-budget","Th\u1eed l\xe0m ng\u01b0\u1eddi l\u1eadp ng\xe2n s\xe1ch","Ph\xe2n b\u1ed5 10 \u0111i\u1ec3m tr\xf2 ch\u01a1i cho m\u1ed9t tu\u1ea7n gi\u1ea3 \u0111\u1ecbnh.",A.a(["Nhu c\u1ea7u","Ti\u1ebft ki\u1ec7m","D\u1ef1 ph\xf2ng"],m),A.a([4,2,1],l),"\u0110\xe2y l\xe0 b\xe0i t\u1eadp r\xe0ng bu\u1ed9c, kh\xf4ng ph\u1ea3i t\u1ef7 l\u1ec7 t\xe0i ch\xednh d\xe0nh cho m\u1ecdi gia \u0111\xecnh. Sau c\xe1c m\u1ee9c t\u1ed1i thi\u1ec3u, b\u1ea1n c\xf3 th\u1ec3 ch\u1ecdn \u01b0u ti\xean kh\xe1c nhau."),A.L("finance-scam","\u0110\u1ecdc m\u1ed9t l\u1eddi h\u1ee9a qu\xe1 h\u1ea5p d\u1eabn","M\u1ed9t tin nh\u1eafn h\u1ee9a \u201cl\xe3i ch\u1eafc ch\u1eafn, chuy\u1ec3n ti\u1ec1n ngay\u201d. Ch\u1ecdn h\xe0nh \u0111\u1ed9ng gi\xfap \u0111\xe1nh gi\xe1 \u0111\xe1ng tin h\u01a1n.",A.a(["Ki\u1ec3m tra t\u1ed5 ch\u1ee9c qua k\xeanh ch\xednh th\u1ee9c \u0111\u1ed9c l\u1eadp.","Chuy\u1ec3n ngay v\xec c\xf3 \u0111\u1ed3ng h\u1ed3 \u0111\u1ebfm ng\u01b0\u1ee3c.","H\u1ecfi ng\u01b0\u1eddi l\u1edbn \u0111\xe1ng tin tr\u01b0\u1edbc khi cung c\u1ea5p th\xf4ng tin.","Tin m\u1ecdi \u1ea3nh ch\u1ee5p l\u1ee3i nhu\u1eadn."],m),A.a([0,2],l),"\xc1p l\u1ef1c th\u1eddi gian v\xe0 l\u1eddi h\u1ee9a ch\u1eafc ch\u1eafn c\u1ea7n \u0111\u01b0\u1ee3c ki\u1ec3m ch\u1ee9ng. Kh\xf4ng chuy\u1ec3n ti\u1ec1n ho\u1eb7c \u0111\u01b0a th\xf4ng tin ch\u1ec9 d\u1ef1a tr\xean tin nh\u1eafn.")],k),"digital",A.a([A.t("digital-private","\u0110i\u1ec1u g\xec n\xean gi\u1eef ri\xeang?","Ph\xe2n lo\u1ea1i khi \u0111\u0103ng c\xf4ng khai tr\xean m\u1ea1ng.",A.a(["M\u1eadt kh\u1ea9u \u0111\u0103ng nh\u1eadp","\u0110\u1ecba ch\u1ec9 nh\xe0 ch\xednh x\xe1c","B\xe0i v\u1ebd kh\xf4ng c\xf3 th\xf4ng tin c\xe1 nh\xe2n"],m),A.a(["Th\xf4ng tin nh\u1ea1y c\u1ea3m","C\xf3 th\u1ec3 chia s\u1ebb sau khi xem x\xe9t"],m),A.a([0,0,1],l),"M\u1eadt kh\u1ea9u v\xe0 \u0111\u1ecba ch\u1ec9 ch\xednh x\xe1c c\u1ea7n b\u1ea3o v\u1ec7; k\u1ec3 c\u1ea3 b\xe0i v\u1ebd c\u0169ng n\xean xem l\u1ea1i quy\u1ec1n ri\xeang t\u01b0 v\xe0 s\u1ef1 \u0111\u1ed3ng \xfd c\u1ee7a ng\u01b0\u1eddi li\xean quan.",o,r),A.t("digital-tools","Ch\u1ecdn c\xf4ng c\u1ee5 \u0111\xfang vi\u1ec7c","Gh\xe9p nhu c\u1ea7u v\u1edbi c\xf4ng c\u1ee5 ph\xf9 h\u1ee3p nh\u1ea5t.",A.a(["T\xednh t\u1ed5ng b\u1ea3ng s\u1ed1","Vi\u1ebft b\u1ea3n nh\xe1p","T\xecm th\xf4ng tin tr\xean web"],m),A.a(["Tr\xecnh so\u1ea1n th\u1ea3o","C\xf4ng c\u1ee5 t\xecm ki\u1ebfm","B\u1ea3ng t\xednh"],m),A.a([2,0,1],l),"Ch\u1ecdn c\xf4ng c\u1ee5 theo nhi\u1ec7m v\u1ee5 gi\xfap l\xe0m vi\u1ec7c hi\u1ec7u qu\u1ea3 h\u01a1n; kh\xf4ng c\xf4ng c\u1ee5 n\xe0o lu\xf4n \u0111\xfang cho m\u1ecdi vi\u1ec7c.",s,r),A.U("digital-verify","D\u1eebng l\u1ea1i tr\u01b0\u1edbc khi chia s\u1ebb","S\u1eafp x\u1ebfp c\xe1c b\u01b0\u1edbc ki\u1ec3m tra tin g\xe2y s\u1ed1c.",A.a(["\u0110\u1ed1i chi\u1ebfu ngu\u1ed3n \u0111\u1ed9c l\u1eadp v\xe0 ng\xe0y \u0111\u0103ng.","Ch\u1ec9 chia s\u1ebb khi \u0111\xe3 hi\u1ec3u ng\u1eef c\u1ea3nh.","\u0110\u1ecdc to\xe0n b\xe0i v\xe0 x\xe1c \u0111\u1ecbnh ngu\u1ed3n g\u1ed1c."],m),A.a([2,0,1],l),"\u0110\u1ecdc ngu\u1ed3n g\u1ed1c \u2192 \u0111\u1ed1i chi\u1ebfu \u2192 quy\u1ebft \u0111\u1ecbnh chia s\u1ebb; ti\xeau \u0111\u1ec1 v\xe0 l\u01b0\u1ee3t th\xedch kh\xf4ng thay cho b\u1eb1ng ch\u1ee9ng.",q),A.t("digital-ai","Hi\u1ec3u gi\u1edbi h\u1ea1n c\u1ee7a AI","\u0110i\u1ec1n t\u1eeb v\xe0o quy t\u1eafc d\xf9ng tr\u1ee3 l\xfd h\u1ecdc t\u1eadp.",A.a(["AI c\xf3 th\u1ec3 t\u1ea1o c\xe2u tr\u1ea3 l\u1eddi ___ d\xf9 nghe t\u1ef1 tin.","Th\xf4ng tin quan tr\u1ecdng c\u1ea7n \u0111\u01b0\u1ee3c ___ b\u1eb1ng ngu\u1ed3n ph\xf9 h\u1ee3p."],m),A.a(["sai","ki\u1ec3m ch\u1ee9ng","lu\xf4n \u0111\xfang"],m),A.a([0,1],l),"V\u0103n b\u1ea3n tr\xf4i ch\u1ea3y kh\xf4ng \u0111\u1ea3m b\u1ea3o \u0111\xfang. Ki\u1ec3m tra ngu\u1ed3n, ph\xe9p t\xednh v\xe0 ng\u1eef c\u1ea3nh, nh\u1ea5t l\xe0 th\xf4ng tin quan tr\u1ecdng.",n,r),A.L("digital-phishing","\u0110i\u1ec1u tra tin nh\u1eafn gi\u1ea3 m\u1ea1o","Tin nh\u1eafn y\xeau c\u1ea7u m\u1eadt kh\u1ea9u \u0111\u1ec3 \u201cx\xe1c minh t\xe0i kho\u1ea3n\u201d. Ch\u1ecdn c\xe1ch x\u1eed l\xfd ph\xf9 h\u1ee3p.",A.a(["M\u1edf app b\u1eb1ng bi\u1ec3u t\u01b0\u1ee3ng quen thu\u1ed9c \u0111\u1ec3 ki\u1ec3m tra.","G\u1eedi m\u1eadt kh\u1ea9u trong h\u1ed9p chat.","B\xe1o cho ng\u01b0\u1eddi l\u1edbn \u0111\xe1ng tin v\xe0 d\xf9ng k\xeanh h\u1ed7 tr\u1ee3 ch\xednh th\u1ee9c.","B\u1ea5m m\u1ecdi li\xean k\u1ebft \u0111\u1ec3 xem c\xf3 th\u1eadt kh\xf4ng."],m),A.a([0,2],l),"\u0110i v\xe0o \u1ee9ng d\u1ee5ng ho\u1eb7c k\xeanh ch\xednh th\u1ee9c thay v\xec li\xean k\u1ebft \u0111\xe1ng ng\u1edd. Kh\xf4ng chia s\u1ebb m\u1eadt kh\u1ea9u hay m\xe3 x\xe1c nh\u1eadn."),A.c9("digital-project","L\u1eadp k\u1ebf ho\u1ea1ch s\u1ea3n ph\u1ea9m s\u1ed1","Chia 10 phi\xean l\xe0m vi\u1ec7c cho d\u1ef1 \xe1n nh\xf3m gi\u1ea3 l\u1eadp.",A.a(["Kh\xe1m ph\xe1 nhu c\u1ea7u","T\u1ea1o s\u1ea3n ph\u1ea9m","Ki\u1ec3m tra v\xe0 s\u1eeda"],m),A.a([2,4,2],l),"D\xe0nh th\u1eddi gian cho nhu c\u1ea7u v\xe0 ki\u1ec3m tra gi\xfap tr\xe1nh x\xe2y nhanh m\u1ed9t s\u1ea3n ph\u1ea9m kh\xf4ng d\xf9ng \u0111\u01b0\u1ee3c; c\xf3 nhi\u1ec1u c\xe1ch ph\xe2n b\u1ed5 h\u1ee3p l\u1ec7.")],k)],u.N,u.X)})
t($,"ju","fM",()=>{var s="V\u1eadn d\u1ee5ng",r="matchPairs",q="Th\u1eed th\xe1ch",p=u.s,o=u.t,n=u.J
return A.d(["logic",A.a([A.U("logic-investigate","T\u1eeb quy lu\u1eadt \u0111\u1ebfn ph\u1ea3n v\xed d\u1ee5","S\u1eafp x\u1ebfp quy tr\xecnh ki\u1ec3m tra m\u1ed9t quy lu\u1eadt \u0111\u01b0\u1ee3c ph\u1ecfng \u0111o\xe1n.",A.a(["T\xecm tr\u01b0\u1eddng h\u1ee3p c\xf3 th\u1ec3 b\xe1c b\u1ecf.","Quan s\xe1t v\xe0i v\xed d\u1ee5.","N\xeau ph\u1ecfng \u0111o\xe1n.","S\u1eeda ho\u1eb7c ch\u1ee9ng minh ph\u1ecfng \u0111o\xe1n."],p),A.a([1,2,0,3],o),"M\u1ed9t v\xe0i v\xed d\u1ee5 \u0111\xfang ch\u01b0a ch\u1ee9ng minh m\u1ec7nh \u0111\u1ec1 t\u1ed5ng qu\xe1t; ph\u1ea3n v\xed d\u1ee5 c\xf3 th\u1ec3 b\xe1c b\u1ecf n\xf3.",s),A.L("logic-counterexample-transfer","Ph\u1ea3n v\xed d\u1ee5 c\xf3 s\u1ee9c m\u1ea1nh g\xec?","M\u1ec7nh \u0111\u1ec1: \u201cM\u1ecdi s\u1ed1 ch\u1eb5n \u0111\u1ec1u chia h\u1ebft cho 4.\u201d Ch\u1ecdn c\xe1c ph\u1ea3n v\xed d\u1ee5.",A.a(["6","8","10","12"],p),A.a([0,2],o),"6 v\xe0 10 ch\u1eb5n nh\u01b0ng kh\xf4ng chia h\u1ebft cho 4. Ch\u1ec9 c\u1ea7n m\u1ed9t ph\u1ea3n v\xed d\u1ee5 \u0111\xe3 b\xe1c b\u1ecf m\u1ec7nh \u0111\u1ec1 m\u1ecdi.")],n),"math",A.a([A.t("math-percent-transfer","M\u1ed9t l\u01b0\u1ee3ng, nhi\u1ec1u c\xe1ch vi\u1ebft","Gh\xe9p ph\xe2n s\u1ed1 v\u1edbi d\u1ea1ng t\u01b0\u01a1ng \u0111\u01b0\u01a1ng.",A.a(["1/2","3/4","1/4"],p),A.a(["25%","50%","75%"],p),A.a([1,2,0],o),"\u0110\u1ed5i ph\u1ea7n tr\u0103m b\u1eb1ng c\xe1ch quy v\u1ec1 m\u1eabu 100. Ph\xe2n s\u1ed1 b\u1eb1ng nhau bi\u1ec3u di\u1ec5n c\xf9ng t\u1ef7 l\u1ec7.",r,s),A.L("math-comparison","So s\xe1nh m\xe0 kh\xf4ng \u0111o\xe1n","Ch\u1ecdn c\xe1c b\u1ea5t \u0111\u1eb3ng th\u1ee9c \u0111\xfang.",A.a(["2/3 > 1/2","1/8 > 1/4","3/5 = 6/10","3/4 < 1/2"],p),A.a([0,2],o),"Quy \u0111\u1ed3ng ho\u1eb7c d\xf9ng m\xf4 h\xecnh c\xf9ng m\u1ed9t to\xe0n th\u1ec3 \u0111\u1ec3 so s\xe1nh. M\u1eabu l\u1edbn h\u01a1n kh\xf4ng l\xe0m ph\u1ea7n l\u1edbn h\u01a1n.")],n),"science",A.a([A.U("science-fair-test","Thi\u1ebft k\u1ebf m\u1ed9t ph\xe9p th\u1eed","S\u1eafp x\u1ebfp quy tr\xecnh th\u1eed t\xe1c \u0111\u1ed9ng c\u1ee7a l\u1ef1c l\xean xe m\xf4 h\xecnh.",A.a(["\u0110o v\xe0 l\u1eb7p l\u1ea1i.","\u0110\u1eb7t c\xe2u h\u1ecfi.","Gi\u1eef xe, m\u1eb7t \u0111\u01b0\u1eddng nh\u01b0 nhau; thay l\u1ef1c.","So s\xe1nh k\u1ebft qu\u1ea3."],p),A.a([1,2,0,3],o),"Ki\u1ec3m so\xe1t y\u1ebfu t\u1ed1 v\xe0 l\u1eb7p l\u1ea1i gi\xfap ph\xe2n bi\u1ec7t t\xe1c \u0111\u1ed9ng c\u1ee7a l\u1ef1c v\u1edbi nhi\u1ec5u \u0111o.",s),A.eh("science-motion-model","Th\u1eddi gian v\xe0 qu\xe3ng \u0111\u01b0\u1eddng","Trong m\xf4 h\xecnh chuy\u1ec3n \u0111\u1ed9ng \u0111\u1ec1u, m\u1ed7i \u0111\u01a1n v\u1ecb t\u1ed1c \u0111\u1ed9 l\xe0 1 m/s v\xe0 m\u1ed7i \u0111\u01a1n v\u1ecb th\u1eddi gian l\xe0 1 s.","T\u1ed1c \u0111\u1ed9","Th\u1eddi gian",9,"3 m/s \xd7 3 s = 9 m. M\xf4 h\xecnh gi\u1ea3 \u0111\u1ecbnh t\u1ed1c \u0111\u1ed9 kh\xf4ng \u0111\u1ed5i; gia t\u1ed1c c\u1ea7n m\xf4 h\xecnh kh\xe1c.")],n),"data",A.a([A.t("data-statistics","Ch\u1ecdn \u0111\u1ea1i l\u01b0\u1ee3ng ph\xf9 h\u1ee3p","Gh\xe9p m\xf4 t\u1ea3 v\u1edbi \u0111\u1ea1i l\u01b0\u1ee3ng.",A.a(["T\u1ed5ng chia s\u1ed1 gi\xe1 tr\u1ecb","Gi\xe1 tr\u1ecb gi\u1eefa sau khi s\u1eafp x\u1ebfp","Gi\xe1 tr\u1ecb xu\u1ea5t hi\u1ec7n nhi\u1ec1u nh\u1ea5t"],p),A.a(["Trung v\u1ecb","M\u1ed1t","Trung b\xecnh"],p),A.a([2,0,1],o),"Ba \u0111\u1ea1i l\u01b0\u1ee3ng m\xf4 t\u1ea3 c\xe1c \u0111\u1eb7c \u0111i\u1ec3m kh\xe1c nhau c\u1ee7a d\u1eef li\u1ec7u.",r,s),A.L("data-bias","M\u1ed9t kh\u1ea3o s\xe1t c\xf3 \u0111\u1ea1i di\u1ec7n?","Mu\u1ed1n bi\u1ebft c\xe1ch to\xe0n tr\u01b0\u1eddng \u0111i h\u1ecdc. Ch\u1ecdn bi\u1ec7n ph\xe1p gi\u1ea3m thi\xean l\u1ec7ch.",A.a(["L\u1ea5y m\u1eabu \u1edf nhi\u1ec1u kh\u1ed1i l\u1edbp.","Ch\u1ec9 h\u1ecfi c\xe2u l\u1ea1c b\u1ed9 xe \u0111\u1ea1p.","N\xeau r\xf5 c\xe1ch ch\u1ecdn m\u1eabu v\xe0 s\u1ed1 ng\u01b0\u1eddi tr\u1ea3 l\u1eddi.","B\u1ecf c\xe2u tr\u1ea3 l\u1eddi kh\xf4ng h\u1ee3p d\u1ef1 \u0111o\xe1n."],p),A.a([0,2],o),"Ph\u1ea1m vi l\u1ea5y m\u1eabu v\xe0 c\xe1ch thu th\u1eadp quy\u1ebft \u0111\u1ecbnh k\u1ebft lu\u1eadn c\xf3 \xe1p d\u1ee5ng cho to\xe0n tr\u01b0\u1eddng hay kh\xf4ng.")],n),"geometry",A.a([A.t("geometry-measures","\u0110\u01a1n v\u1ecb n\xf3i \u0111i\u1ec1u g\xec?","Gh\xe9p ph\xe9p \u0111o v\u1edbi lo\u1ea1i \u0111\u01a1n v\u1ecb.",A.a(["\u0110\u1ed9 d\xe0i c\u1ea1nh","Di\u1ec7n t\xedch m\u1eb7t","Th\u1ec3 t\xedch kh\u1ed1i"],p),A.a(["cm\xb3","cm","cm\xb2"],p),A.a([1,2,0],o),"\u0110\u1ed9 d\xe0i m\u1ed9t chi\u1ec1u, di\u1ec7n t\xedch hai chi\u1ec1u v\xe0 th\u1ec3 t\xedch ba chi\u1ec1u c\u1ea7n \u0111\u01a1n v\u1ecb kh\xe1c nhau.",r,s),A.eh("geometry-area-lab","Thi\u1ebft k\u1ebf di\u1ec7n t\xedch","D\u1ef1ng h\xecnh ch\u1eef nh\u1eadt b\u1eb1ng hai c\u1ea1nh nguy\xean, m\u1ed7i c\u1ea1nh t\u1ed1i \u0111a 3 \u0111\u01a1n v\u1ecb.","Chi\u1ec1u d\xe0i","Chi\u1ec1u r\u1ed9ng",6,"H\xecnh 2 \xd7 3 v\xe0 3 \xd7 2 c\xf9ng c\xf3 di\u1ec7n t\xedch 6; \u0111\u1ed5i h\u01b0\u1edbng kh\xf4ng \u0111\u1ed5i di\u1ec7n t\xedch.")],n),"coding",A.a([A.U("coding-debug-cycle","G\u1ee1 l\u1ed7i c\xf3 ph\u01b0\u01a1ng ph\xe1p","S\u1eafp x\u1ebfp quy tr\xecnh g\u1ee1 l\u1ed7i thay v\xec s\u1eeda ng\u1eabu nhi\xean.",A.a(["S\u1eeda nguy\xean nh\xe2n \u0111\xe3 x\xe1c \u0111\u1ecbnh.","T\xe1i hi\u1ec7n l\u1ed7i v\u1edbi \u0111\u1ea7u v\xe0o nh\u1ecf.","Ch\u1ea1y l\u1ea1i ca l\u1ed7i v\xe0 ca b\xecnh th\u01b0\u1eddng.","Theo d\u1ea5u b\u01b0\u1edbc sai \u0111\u1ea7u ti\xean."],p),A.a([1,3,0,2],o),"T\xe1i hi\u1ec7n \u2192 x\xe1c \u0111\u1ecbnh nguy\xean nh\xe2n \u2192 s\u1eeda \u2192 ki\u1ec3m tra h\u1ed3i quy gi\xfap tr\xe1nh t\u1ea1o l\u1ed7i m\u1edbi.",s),A.L("coding-tests","Ki\u1ec3m tra ranh gi\u1edbi","H\xe0m nh\u1eadn tu\u1ed5i nguy\xean t\u1eeb 6 \u0111\u1ebfn 18. Ch\u1ecdn c\xe1c c\u1eb7p \u0111\u1ea7u v\xe0o ki\u1ec3m tra hai ranh gi\u1edbi trong/ngo\xe0i.",A.a(["5 v\xe0 6","10 v\xe0 11","18 v\xe0 19","12 v\xe0 13"],p),A.a([0,2],o),"5/6 ki\u1ec3m tra c\u1eadn d\u01b0\u1edbi; 18/19 ki\u1ec3m tra c\u1eadn tr\xean. Ca gi\u1eefa mi\u1ec1n ch\u01b0a ki\u1ec3m tra l\u1ed7i l\u1ec7ch m\u1ed9t \u0111\u01a1n v\u1ecb.")],n),"circuits",A.a([A.t("circuits-concepts","\u0110\u1ecdc m\u1ea1ch b\u1eb1ng kh\xe1i ni\u1ec7m","Gh\xe9p \u0111\u1ea1i l\u01b0\u1ee3ng v\xe0 \u0111\u01a1n v\u1ecb.",A.a(["Hi\u1ec7u \u0111i\u1ec7n th\u1ebf","C\u01b0\u1eddng \u0111\u1ed9 d\xf2ng \u0111i\u1ec7n","\u0110i\u1ec7n tr\u1edf"],p),A.a(["ohm (\u03a9)","volt (V)","ampere (A)"],p),A.a([1,2,0],o),"C\xe1c \u0111\u1ea1i l\u01b0\u1ee3ng c\xf3 \u0111\u01a1n v\u1ecb ri\xeang; trong m\xf4 h\xecnh \u0111i\u1ec7n tr\u1edf thu\u1ea7n c\xf3 th\u1ec3 li\xean h\u1ec7 b\u1eb1ng U = I \xd7 R.",r,s),A.L("circuits-safety","Th\u1eed nghi\u1ec7m c\xf3 tr\xe1ch nhi\u1ec7m","Ch\u1ecdn c\xe1ch kh\xe1m ph\xe1 ph\xf9 h\u1ee3p cho ng\u01b0\u1eddi h\u1ecdc.",A.a(["D\xf9ng m\xf4 ph\u1ecfng trong app.","Ch\u1ecdc v\u1eadt v\xe0o \u1ed5 \u0111i\u1ec7n \u0111\u1ec3 th\u1eed d\u1eabn \u0111i\u1ec7n.","Ch\u1ec9 d\xf9ng b\u1ed9 h\u1ecdc \u0111i\u1ec7n \xe1p th\u1ea5p v\u1edbi ng\u01b0\u1eddi l\u1edbn h\u01b0\u1edbng d\u1eabn.","N\u1ed1i t\u1eaft pin \u0111\u1ec3 xem c\xf3 n\xf3ng kh\xf4ng."],p),A.a([0,2],o),"M\xf4 ph\u1ecfng gi\xfap th\u1eed kh\xf4ng g\xe2y nguy hi\u1ec3m. Kh\xf4ng d\xf9ng \u0111i\u1ec7n l\u01b0\u1edbi hay c\u1ed1 t\xecnh n\u1ed1i t\u1eaft ngu\u1ed3n.")],n),"probability",A.a([A.t("probability-language","T\u1eeb c\u01a1 h\u1ed9i \u0111\u1ebfn con s\u1ed1","Gh\xe9p x\xe1c su\u1ea5t v\u1edbi m\xf4 t\u1ea3 trong m\xf4 h\xecnh.",A.a(["0","1/2","1"],p),A.a(["Ch\u1eafc ch\u1eafn","Kh\xf4ng th\u1ec3","Hai k\u1ebft qu\u1ea3 \u0111\u1ed1i x\u1ee9ng, \u0111\u1ed3ng kh\u1ea3 n\u0103ng"],p),A.a([1,2,0],o),"X\xe1c su\u1ea5t t\u1eeb 0 \u0111\u1ebfn 1; 1/2 c\u1ea7n gi\u1ea3 \u0111\u1ecbnh c\xe1c k\u1ebft qu\u1ea3 li\xean quan \u0111\u1ed3ng kh\u1ea3 n\u0103ng.",r,s),A.L("probability-independence","\u0110\u1ed3ng xu c\xf3 tr\xed nh\u1edb kh\xf4ng?","\u0110\u1ed3ng xu c\xe2n \u0111\u1ed1i, c\xe1c l\u1ea7n tung \u0111\u1ed9c l\u1eadp. Ch\u1ecdn ph\xe1t bi\u1ec3u \u0111\xfang sau ba l\u1ea7n ng\u1eeda.",A.a(["L\u1ea7n ti\u1ebfp theo v\u1eabn c\xf3 x\xe1c su\u1ea5t ng\u1eeda 1/2.","L\u1ea7n ti\u1ebfp theo ch\u1eafc ch\u1eafn s\u1ea5p.","M\u1ed9t chu\u1ed7i ng\u1eafn kh\xf4ng \u0111\u1ee7 ch\u1ee9ng minh \u0111\u1ed3ng xu l\u1ec7ch.","\u0110\u1ed3ng xu ph\u1ea3i b\xf9 l\u1ea1i c\xe1c l\u1ea7n ng\u1eeda."],p),A.a([0,2],o),"\u0110\u1ed9c l\u1eadp ngh\u0129a l\xe0 c\xe1c l\u1ea7n tr\u01b0\u1edbc kh\xf4ng bu\u1ed9c l\u1ea7n sau b\xf9 l\u1ea1i. Ki\u1ec3m tra \u0111\u1ed9 l\u1ec7ch c\u1ea7n \u0111\u1ee7 d\u1eef li\u1ec7u v\xe0 m\xf4 h\xecnh th\u1ed1ng k\xea.")],n),"algebra",A.a([A.U("algebra-solve-steps","Gi\u1ea3i v\xe0 ki\u1ec3m ch\u1ee9ng","S\u1eafp x\u1ebfp l\u1eddi gi\u1ea3i ph\u01b0\u01a1ng tr\xecnh 2x + 3 = 11.",A.a(["Chia hai v\u1ebf cho 2: x = 4.","Tr\u1eeb 3 \u1edf hai v\u1ebf: 2x = 8.","Thay x = 4 v\xe0o ph\u01b0\u01a1ng tr\xecnh ban \u0111\u1ea7u."],p),A.a([1,0,2],o),"M\u1ed7i ph\xe9p bi\u1ebfn \u0111\u1ed5i gi\u1eef t\u01b0\u01a1ng \u0111\u01b0\u01a1ng; thay l\u1ea1i x\xe1c nh\u1eadn 2 \xd7 4 + 3 = 11.",s),A.t("algebra-functions","\u0110\u1ecdc quy t\u1eafc h\xe0m s\u1ed1","V\u1edbi y = 2x + 1, gh\xe9p x v\u1edbi y.",A.a(["x = 0","x = 2","x = \u22121"],p),A.a(["5","\u22121","1"],p),A.a([2,0,1],o),"Thay t\u1eebng gi\xe1 tr\u1ecb v\xe0o c\xf9ng quy t\u1eafc. H\u1ec7 s\u1ed1 2 m\xf4 t\u1ea3 m\u1ee9c thay \u0111\u1ed5i; 1 l\xe0 gi\xe1 tr\u1ecb t\u1ea1i x = 0.",r,q)],n),"optimization",A.a([A.c9("optimization-time","T\u1ed1i \u01b0u v\u1edbi nhi\u1ec1u \u0111i\u1ec1u ki\u1ec7n","Chia 10 l\u01b0\u1ee3t x\u1eed l\xfd cho m\u1ed9t h\u1ec7 th\u1ed1ng gi\u1ea3 l\u1eadp.",A.a(["T\xednh to\xe1n","Ki\u1ec3m tra","D\u1ef1 ph\xf2ng"],p),A.a([5,2,1],o),"Ph\u01b0\u01a1ng \xe1n kh\u1ea3 thi ph\u1ea3i th\u1ecfa t\u1ed5ng v\xe0 t\u1eebng c\u1eadn d\u01b0\u1edbi; ch\u1ec9 t\u1ed1i \u0111a t\xednh to\xe1n c\xf3 th\u1ec3 l\xe0m m\u1ea5t \u0111\u1ed9 tin c\u1eady."),A.L("optimization-greedy","Nhanh tr\u01b0\u1edbc m\u1eaft c\xf3 lu\xf4n t\u1ed1t?","Ch\u1ecdn nh\u1eadn \u0111\u1ecbnh \u0111\xfang v\u1ec1 l\u1ef1a ch\u1ecdn tham lam.",A.a(["C\xf3 b\xe0i to\xe1n c\u1ea7n ch\u1ee9ng minh t\xednh \u0111\xfang c\u1ee7a chi\u1ebfn l\u01b0\u1ee3c.","Ch\u1ecdn r\u1ebb nh\u1ea5t m\u1ed7i b\u01b0\u1edbc lu\xf4n t\u1ed1i \u01b0u m\u1ecdi b\xe0i.","M\u1ed9t ph\u1ea3n v\xed d\u1ee5 \u0111\u1ee7 b\xe1c b\u1ecf l\u1eddi kh\u1eb3ng \u0111\u1ecbnh lu\xf4n t\u1ed1i \u01b0u.","Ch\u1ea1y nhanh \u0111\u1ed3ng ngh\u0129a k\u1ebft qu\u1ea3 t\u1ed1i \u01b0u."],p),A.a([0,2],o),"T\u1ed1c \u0111\u1ed9 v\xe0 t\u1ed1i \u01b0u l\xe0 hai t\xednh ch\u1ea5t kh\xe1c nhau. Chi\u1ebfn l\u01b0\u1ee3c c\u1ee5c b\u1ed9 c\u1ea7n \u0111i\u1ec1u ki\u1ec7n ho\u1eb7c ch\u1ee9ng minh \u0111\u1ec3 \u0111\u1ea3m b\u1ea3o to\xe0n c\u1ee5c.")],n),"geography",A.a([A.t("geography-coordinates","Ng\xf4n ng\u1eef b\u1ea3n \u0111\u1ed3","Gh\xe9p t\u1ecda \u0111\u1ed9 ho\u1eb7c h\u01b0\u1edbng v\u1edbi m\xf4 t\u1ea3.",A.a(["V\u0129 \u0111\u1ed9 0\xb0","Kinh \u0111\u1ed9 0\xb0","V\u0129 \u0111\u1ed9 90\xb0B"],p),A.a(["C\u1ef1c B\u1eafc","X\xedch \u0111\u1ea1o","Kinh tuy\u1ebfn g\u1ed1c"],p),A.a([1,2,0],o),"V\u0129 \u0111\u1ed9 \u0111o v\u1ecb tr\xed b\u1eafc\u2013nam, kinh \u0111\u1ed9 \u0111o \u0111\xf4ng\u2013t\xe2y theo quy \u01b0\u1edbc.",r,s),A.L("geography-map","\u0110\u1ecdc b\u1ea3n \u0111\u1ed3 c\xf3 ph\xea ph\xe1n","Ch\u1ecdn \u0111i\u1ec1u c\u1ea7n ki\u1ec3m tra tr\u01b0\u1edbc khi so s\xe1nh hai b\u1ea3n \u0111\u1ed3.",A.a(["T\u1ef7 l\u1ec7 v\xe0 ph\xe9p chi\u1ebfu.","M\xe0u \u0111\u1eb9p h\u01a1n ngh\u0129a l\xe0 \u0111\xfang h\u01a1n.","Ng\xe0y v\xe0 ngu\u1ed3n d\u1eef li\u1ec7u.","M\u1ecdi ph\xe9p chi\u1ebfu \u0111\u1ec1u b\u1ea3o to\xe0n c\u1ea3 di\u1ec7n t\xedch l\u1eabn g\xf3c."],p),A.a([0,2],o),"Ph\xe9p chi\u1ebfu t\u1ea1o \u0111\xe1nh \u0111\u1ed5i h\xecnh h\u1ecdc; d\u1eef li\u1ec7u v\xe0 th\u1eddi \u0111i\u1ec3m c\u0169ng quy\u1ebft \u0111\u1ecbnh c\xe1ch di\u1ec5n gi\u1ea3i.")],n),"marxism",A.a([A.U("marxism-reading","\u0110\u1ecdc h\u1ecdc thuy\u1ebft theo ng\u1eef c\u1ea3nh","S\u1eafp x\u1ebfp quy tr\xecnh \u0111\u1ecdc m\u1ed9t lu\u1eadn \u0111i\u1ec3m l\u1ecbch s\u1eed t\u01b0 t\u01b0\u1edfng.",A.a(["\u0110\u1ed1i chi\u1ebfu c\xe1ch di\u1ec5n gi\u1ea3i v\xe0 ph\u1ea3n bi\u1ec7n.","X\xe1c \u0111\u1ecbnh t\xe1c gi\u1ea3, v\u0103n b\u1ea3n v\xe0 th\u1eddi \u0111i\u1ec3m.","T\xf3m t\u1eaft lu\u1eadn \u0111i\u1ec3m k\xe8m \u0111o\u1ea1n l\xe0m c\u0103n c\u1ee9.","N\xeau gi\u1edbi h\u1ea1n c\u1ee7a k\u1ebft lu\u1eadn."],p),A.a([1,2,0,3],o),"\u0110\u1ecdc ngu\u1ed3n v\xe0 ng\u1eef c\u1ea3nh tr\u01b0\u1edbc, t\xe1ch m\xf4 t\u1ea3 t\u01b0 t\u01b0\u1edfng kh\u1ecfi vi\u1ec7c t\xe1n th\xe0nh t\u01b0 t\u01b0\u1edfng.",q),A.L("marxism-source-literacy","Ngu\u1ed3n g\u1ed1c v\xe0 di\u1ec5n gi\u1ea3i","Ch\u1ecdn c\xe1ch l\xe0m h\u1ed7 tr\u1ee3 vi\u1ec7c tr\xecnh b\xe0y m\u1ed9t h\u1ecdc thuy\u1ebft ch\xednh x\xe1c.",A.a(["Tr\xedch \u0111\xfang v\u0103n b\u1ea3n v\xe0 n\xeau ng\u1eef c\u1ea3nh.","G\xe1n m\u1ed9t c\xe2u lan truy\u1ec1n cho t\xe1c gi\u1ea3 m\xe0 kh\xf4ng tra ngu\u1ed3n.","Ph\xe2n bi\u1ec7t ngu\u1ed3n s\u01a1 c\u1ea5p v\u1edbi b\xecnh lu\u1eadn v\u1ec1 sau.","B\u1ecf qua m\u1ecdi c\xe1ch di\u1ec5n gi\u1ea3i kh\xe1c."],p),A.a([0,2],o),"Ngu\u1ed3n s\u01a1 c\u1ea5p v\xe0 \u0111\u1ed1i chi\u1ebfu gi\xfap ki\u1ec3m tra c\xe1ch di\u1ec5n gi\u1ea3i; kh\xe1c bi\u1ec7t quan \u0111i\u1ec3m c\u1ea7n \u0111\u01b0\u1ee3c tr\xecnh b\xe0y r\xf5 v\xe0 c\xf4ng b\u1eb1ng.")],n),"painting",A.a([A.t("painting-observe","\u0110\u1ecdc ng\xf4n ng\u1eef th\u1ecb gi\xe1c","Gh\xe9p y\u1ebfu t\u1ed1 v\u1edbi \u0111i\u1ec1u n\xf3 m\xf4 t\u1ea3.",A.a(["S\u1eafc \u0111\u1ed9","B\u1ed1 c\u1ee5c","T\u01b0\u01a1ng ph\u1ea3n"],p),A.a(["C\xe1ch s\u1eafp x\u1ebfp th\xe0nh ph\u1ea7n","M\u1ee9c s\xe1ng\u2013t\u1ed1i","M\u1ee9c kh\xe1c bi\u1ec7t gi\u1eefa c\xe1c y\u1ebfu t\u1ed1"],p),A.a([1,0,2],o),"M\xf4 t\u1ea3 c\u1ee5 th\u1ec3 y\u1ebfu t\u1ed1 th\u1ecb gi\xe1c gi\xfap gi\u1ea3i th\xedch c\u1ea3m nh\u1eadn thay v\xec ch\u1ec9 n\xf3i \u0111\u1eb9p ho\u1eb7c x\u1ea5u.",r,s),A.L("painting-interpret","Di\u1ec5n gi\u1ea3i d\u1ef1a v\xe0o \u0111i\u1ec1u th\u1ea5y","Ch\u1ecdn ph\xe1t bi\u1ec3u ph\xe2n bi\u1ec7t quan s\xe1t v\u1edbi di\u1ec5n gi\u1ea3i.",A.a(["C\xf3 th\u1ec3 ch\u1ec9 ra v\u1ecb tr\xed v\xf9ng s\xe1ng trong tranh.","Ch\u1ec9 nh\xecn m\xe0u \u0111\xe3 bi\u1ebft ch\u1eafc \xfd \u0111\u1ecbnh c\u1ee7a h\u1ecda s\u0129.","M\u1ed9t di\u1ec5n gi\u1ea3i n\xean g\u1eafn v\u1edbi chi ti\u1ebft v\xe0 b\u1ed1i c\u1ea3nh.","M\u1ecdi ng\u01b0\u1eddi bu\u1ed9c ph\u1ea3i c\xf3 c\xf9ng c\u1ea3m x\xfac."],p),A.a([0,2],o),"Di\u1ec5n gi\u1ea3i c\xf3 th\u1ec3 \u0111a d\u1ea1ng nh\u01b0ng c\u1ea7n c\u0103n c\u1ee9. \xdd \u0111\u1ecbnh t\xe1c gi\u1ea3 kh\xf4ng th\u1ec3 suy ra ch\u1eafc ch\u1eafn ch\u1ec9 t\u1eeb m\u1ed9t d\u1ea5u hi\u1ec7u.")],n)],u.N,u.X)})
t($,"jv","ey",()=>{var s,r,q="N\u1ec1n t\u1ea3ng",p="V. I. Lenin, Ba ngu\u1ed3n g\u1ed1c v\xe0 ba b\u1ed9 ph\u1eadn c\u1ea5u th\xe0nh c\u1ee7a ch\u1ee7 ngh\u0129a M\xe1c (1913) \xb7 Marxists Internet Archive",o=null,n="Karl Marx, L\u1eddi t\u1ef1a G\xf3p ph\u1ea7n ph\xea ph\xe1n khoa kinh t\u1ebf ch\xednh tr\u1ecb (1859) \xb7 Marxists Internet Archive",m="V\u1eadn d\u1ee5ng",l="Ph\xe2n t\xedch",k="Th\u1eed th\xe1ch",j="J. Paul Getty Museum, Understanding Formal Analysis: Elements of Art / Principles of Design",i="Python Software Foundation, Python 3 Tutorial: Control Flow / Data Structures",h="V\u1eadn d\u1ee5ng Python",g="Ph\xe2n t\xedch Python",f=u.s,e=u.J,d=A.a([A.J(1,A.a(["Tri\u1ebft h\u1ecdc","Kinh t\u1ebf ch\xednh tr\u1ecb","L\u1ecbch s\u1eed h\u1ed9i h\u1ecda"],f),o,"H\xe0ng h\xf3a, lao \u0111\u1ed9ng v\xe0 gi\xe1 tr\u1ecb th\u1eb7ng d\u01b0 thu\u1ed9c kinh t\u1ebf ch\xednh tr\u1ecb M\xe1c. Ba b\u1ed9 ph\u1eadn c\xf3 li\xean h\u1ec7 nh\u01b0ng kh\xf4ng \u0111\u1ed3ng nh\u1ea5t \u0111\u1ed1i t\u01b0\u1ee3ng nghi\xean c\u1ee9u.","Xem \u0111\u1ed1i t\u01b0\u1ee3ng \u0111\u01b0\u1ee3c nghi\xean c\u1ee9u, thay v\xec ch\u1ec9 nh\xecn t\xean t\xe1c gi\u1ea3.","marxism-sources","Trong b\xe0i vi\u1ebft n\u0103m 1913, L\xeanin tr\xecnh b\xe0y ba ngu\u1ed3n g\u1ed1c: tri\u1ebft h\u1ecdc \u0110\u1ee9c, kinh t\u1ebf ch\xednh tr\u1ecb Anh v\xe0 ch\u1ee7 ngh\u0129a x\xe3 h\u1ed9i Ph\xe1p. Ba b\u1ed9 ph\u1eadn \u0111\u01b0\u1ee3c b\xe0n \u0111\u1ebfn l\xe0 tri\u1ebft h\u1ecdc, kinh t\u1ebf ch\xednh tr\u1ecb v\xe0 ch\u1ee7 ngh\u0129a x\xe3 h\u1ed9i khoa h\u1ecdc. B\xe0i h\u1ecdc t\xecm hi\u1ec3u n\u1ed9i dung h\u1ecdc thuy\u1ebft trong b\u1ed1i c\u1ea3nh l\u1ecbch s\u1eed.","M\u1ed9t nh\xf3m \u0111ang \u0111\u1ecdc v\u1ec1 h\xe0ng h\xf3a, lao \u0111\u1ed9ng v\xe0 gi\xe1 tr\u1ecb th\u1eb7ng d\u01b0. Nh\xf3m \u0111ang t\xecm hi\u1ec3u b\u1ed9 ph\u1eadn n\xe0o?",0,A.a(["\u0110\u1ed1i t\u01b0\u1ee3ng l\xe0 c\xe1c quan h\u1ec7 kinh t\u1ebf trong s\u1ea3n xu\u1ea5t v\xe0 trao \u0111\u1ed5i.","M\u1ecdi v\u0103n b\u1ea3n c\u1ee7a M\xe1c \u0111\u1ec1u ch\u1ec9 thu\u1ed9c tri\u1ebft h\u1ecdc.","T\xean t\xe1c gi\u1ea3 quy\u1ebft \u0111\u1ecbnh m\xf4n h\u1ecdc, kh\xf4ng c\u1ea7n xem n\u1ed9i dung."],f),p,q,o,"Ba ngu\u1ed3n g\u1ed1c, ba b\u1ed9 ph\u1eadn"),A.J(2,A.a(["Ai \u0111\xe3 mong mu\u1ed1n thay \u0111\u1ed5i nh\u1ea5t?","C\xf3 th\u1ec3 b\u1ecf qua \u0111i\u1ec1u ki\u1ec7n l\xe0m vi\u1ec7c kh\xf4ng?","C\xf4ng c\u1ee5 v\xe0 quan h\u1ec7 lao \u0111\u1ed9ng thay \u0111\u1ed5i nh\u01b0 th\u1ebf n\xe0o?"],f),o,"C\xe2u h\u1ecfi v\u1ec1 c\xf4ng c\u1ee5 v\xe0 quan h\u1ec7 lao \u0111\u1ed9ng m\u1edf ra vi\u1ec7c kh\u1ea3o s\xe1t c\u1ee5 th\u1ec3. Kh\xf4ng th\u1ec3 t\u1eeb m\u1ed9t v\xed d\u1ee5 k\u1ebft lu\u1eadn c\xf4ng ngh\u1ec7 l\xe0 nguy\xean nh\xe2n duy nh\u1ea5t c\u1ee7a m\u1ecdi bi\u1ebfn \u0111\u1ed5i x\xe3 h\u1ed9i.","Ph\xe2n bi\u1ec7t kh\u1ea3o s\xe1t \u0111i\u1ec1u ki\u1ec7n v\u1eadt ch\u1ea5t v\u1edbi k\u1ebft lu\u1eadn m\xe1y m\xf3c r\u1eb1ng c\xf4ng ngh\u1ec7 quy\u1ebft \u0111\u1ecbnh t\u1ea5t c\u1ea3.","marxism-material-conditions","Trong L\u1eddi t\u1ef1a n\u0103m 1859, M\xe1c nh\u1ea5n m\u1ea1nh quan h\u1ec7 gi\u1eefa \u0111\u1eddi s\u1ed1ng v\u1eadt ch\u1ea5t, quan h\u1ec7 s\u1ea3n xu\u1ea5t v\xe0 \u0111\u1eddi s\u1ed1ng tinh th\u1ea7n. Khi v\u1eadn d\u1ee5ng, c\u1ea7n ch\u1ec9 ra \u0111i\u1ec1u ki\u1ec7n v\xe0 c\u01a1 ch\u1ebf c\u1ee5 th\u1ec3, thay v\xec gi\u1ea3i th\xedch m\u1ecdi bi\u1ebfn \u0111\u1ed5i b\u1eb1ng mong mu\u1ed1n c\xe1 nh\xe2n.","M\xe1y m\xf3c m\u1edbi l\xe0m thay \u0111\u1ed5i c\xe1ch m\u1ed9t x\u01b0\u1edfng ph\xe2n c\xf4ng lao \u0111\u1ed9ng. C\xe2u h\u1ecfi n\xe0o ph\xf9 h\u1ee3p v\u1edbi c\xe1ch ti\u1ebfp c\u1eadn duy v\u1eadt l\u1ecbch s\u1eed?",1,A.a(["\xdd mu\u1ed1n c\xe1 nh\xe2n lu\xf4n l\xe0 nguy\xean nh\xe2n duy nh\u1ea5t.","C\u1ea7n kh\u1ea3o s\xe1t c\u01a1 s\u1edf v\u1eadt ch\u1ea5t v\xe0 c\xe1c quan h\u1ec7 x\xe3 h\u1ed9i c\u1ee5 th\u1ec3.","C\xf4ng ngh\u1ec7 t\u1ef1 quy\u1ebft \u0111\u1ecbnh m\u1ecdi k\u1ebft qu\u1ea3, kh\xf4ng c\u1ea7n con ng\u01b0\u1eddi."],f),n,q,o,"\u0110i\u1ec1u ki\u1ec7n v\u1eadt ch\u1ea5t v\xe0 \xfd th\u1ee9c"),A.J(0,A.a(["Quy\u1ec1n s\u1edf h\u1eefu x\u01b0\u1edfng v\xe0 c\xe1ch t\u1ed5 ch\u1ee9c quan h\u1ec7 lao \u0111\u1ed9ng.","C\xf4ng su\u1ea5t \u0111\u1ed9ng c\u01a1.","\u0110\u1ed9 b\u1ec1n c\u1ee7a l\u01b0\u1ee1i c\u1eaft."],f),o,"Quy\u1ec1n s\u1edf h\u1eefu v\xe0 t\u1ed5 ch\u1ee9c quan h\u1ec7 lao \u0111\u1ed9ng l\xe0 kh\xeda c\u1ea1nh x\xe3 h\u1ed9i c\u1ee7a s\u1ea3n xu\u1ea5t. C\xf4ng su\u1ea5t v\xe0 \u0111\u1ed9 b\u1ec1n m\xf4 t\u1ea3 \u0111\u1eb7c \u0111i\u1ec3m k\u1ef9 thu\u1eadt c\u1ee7a t\u01b0 li\u1ec7u s\u1ea3n xu\u1ea5t.","T\xe1ch thu\u1ed9c t\xednh k\u1ef9 thu\u1eadt c\u1ee7a c\xf4ng c\u1ee5 kh\u1ecfi quan h\u1ec7 x\xe3 h\u1ed9i gi\u1eefa nh\u1eefng ng\u01b0\u1eddi s\u1eed d\u1ee5ng ch\xfang.","marxism-relations","L\u1ef1c l\u01b0\u1ee3ng s\u1ea3n xu\u1ea5t li\xean quan \u0111\u1ebfn ng\u01b0\u1eddi lao \u0111\u1ed9ng, n\u0103ng l\u1ef1c v\xe0 t\u01b0 li\u1ec7u s\u1ea3n xu\u1ea5t. Quan h\u1ec7 s\u1ea3n xu\u1ea5t l\xe0 nh\u1eefng quan h\u1ec7 x\xe3 h\u1ed9i trong qu\xe1 tr\xecnh s\u1ea3n xu\u1ea5t; kh\xf4ng n\xean \u0111\u1ed3ng nh\u1ea5t ch\xfang v\u1edbi b\u1ea3n th\xe2n m\xe1y m\xf3c.","Trong m\u1ed9t x\u01b0\u1edfng, chi ti\u1ebft n\xe0o m\xf4 t\u1ea3 quan h\u1ec7 s\u1ea3n xu\u1ea5t r\xf5 nh\u1ea5t?",2,A.a(["M\u1ecdi th\u1ee9 c\xf3 th\u1ec3 \u0111o \u0111\u01b0\u1ee3c \u0111\u1ec1u l\xe0 quan h\u1ec7 s\u1ea3n xu\u1ea5t.","Quan h\u1ec7 s\u1ea3n xu\u1ea5t ch\u1ec9 l\xe0 t\xecnh b\u1ea1n gi\u1eefa \u0111\u1ed3ng nghi\u1ec7p.","\u0110\xe2y l\xe0 quan h\u1ec7 gi\u1eefa ng\u01b0\u1eddi v\u1edbi ng\u01b0\u1eddi trong s\u1ea3n xu\u1ea5t."],f),n,m,o,"L\u1ef1c l\u01b0\u1ee3ng v\xe0 quan h\u1ec7 s\u1ea3n xu\u1ea5t"),A.J(0,A.a(["m = 40; t\u1ef7 su\u1ea5t 50%.","m = 120; t\u1ef7 su\u1ea5t 150%.","m = 40; t\u1ef7 su\u1ea5t 33,3%."],f),o,"m = 120 \u2212 80 = 40 v\xe0 m/v = 40/80 = 50%. K\u1ebft qu\u1ea3 ch\u1ec9 thu\u1ed9c m\xf4 h\xecnh gi\u1ea3 \u0111\u1ecbnh; kh\xf4ng d\xf9ng tr\u1ef1c ti\u1ebfp \u0111\u1ec3 suy ra l\u1ee3i nhu\u1eadn th\u1ef1c t\u1ebf c\u1ee7a m\u1ed9t doanh nghi\u1ec7p.","Tr\u01b0\u1edbc ti\xean t\xe1ch gi\xe1 tr\u1ecb m\u1edbi th\xe0nh v + m. M\u1eabu s\u1ed1 c\u1ee7a t\u1ef7 su\u1ea5t l\xe0 v.","marxism-surplus","Trong m\xf4 h\xecnh kinh t\u1ebf c\u1ee7a M\xe1c, gi\xe1 tr\u1ecb m\u1edbi do lao \u0111\u1ed9ng t\u1ea1o ra \u0111\u01b0\u1ee3c ph\xe2n th\xe0nh ph\u1ea7n b\xf9 gi\xe1 tr\u1ecb s\u1ee9c lao \u0111\u1ed9ng (v) v\xe0 gi\xe1 tr\u1ecb th\u1eb7ng d\u01b0 (m). T\u1ef7 su\u1ea5t gi\xe1 tr\u1ecb th\u1eb7ng d\u01b0 l\xe0 m/v. Kh\xf4ng \u0111\u1ed3ng nh\u1ea5t gi\xe1 tr\u1ecb m\u1edbi v\u1edbi doanh thu hay m v\u1edbi l\u1ee3i nhu\u1eadn k\u1ebf to\xe1n.","M\xf4 h\xecnh gi\u1ea3 \u0111\u1ecbnh gi\xe1 tr\u1ecb m\u1edbi l\xe0 120 \u0111\u01a1n v\u1ecb, v = 80. Gi\xe1 tr\u1ecb th\u1eb7ng d\u01b0 m v\xe0 t\u1ef7 su\u1ea5t m/v l\xe0 bao nhi\xeau?",1,A.a(["L\u1ea5y 40 chia t\u1ed5ng gi\xe1 tr\u1ecb m\u1edbi 120.","m = 120 \u2212 80; l\u1ea5y m chia v = 80.","Doanh thu lu\xf4n b\u1eb1ng gi\xe1 tr\u1ecb th\u1eb7ng d\u01b0."],f),p,m,o,"\u0110\u1ecdc m\xf4 h\xecnh gi\xe1 tr\u1ecb th\u1eb7ng d\u01b0"),A.J(2,A.a(["Ch\u1ea5p nh\u1eadn v\xec c\xf3 nh\u1eafc \u0111\u1ebfn m\xe1y m\xf3c.","B\xe1c b\u1ecf m\u1ecdi vai tr\xf2 c\u1ee7a k\u1ef9 thu\u1eadt.","Y\xeau c\u1ea7u b\u1eb1ng ch\u1ee9ng v\u1ec1 quan h\u1ec7 lao \u0111\u1ed9ng, th\u1ec3 ch\u1ebf v\xe0 di\u1ec5n bi\u1ebfn l\u1ecbch s\u1eed."],f),o,"Kh\u1ea3o s\xe1t quan h\u1ec7 lao \u0111\u1ed9ng, th\u1ec3 ch\u1ebf v\xe0 qu\xe1 tr\xecnh bi\u1ebfn \u0111\u1ed5i gi\xfap tr\xe1nh gi\u1ea3i th\xedch \u0111\u01a1n tuy\u1ebfn. Vai tr\xf2 c\u1ee7a k\u1ef9 thu\u1eadt c\u1ea7n \u0111\u01b0\u1ee3c ph\xe2n t\xedch c\xf9ng c\xe1c \u0111i\u1ec1u ki\u1ec7n x\xe3 h\u1ed9i c\u1ee5 th\u1ec3.","Ph\xe2n bi\u1ec7t m\u1ed9t m\u1ed1i li\xean h\u1ec7 c\u1ea7n nghi\xean c\u1ee9u v\u1edbi m\u1ed9t k\u1ebft lu\u1eadn tuy\u1ec7t \u0111\u1ed1i.","marxism-social-change","M\xe1c ph\xe2n t\xedch m\u1ed1i li\xean h\u1ec7 v\xe0 xung \u0111\u1ed9t gi\u1eefa l\u1ef1c l\u01b0\u1ee3ng s\u1ea3n xu\u1ea5t v\xe0 quan h\u1ec7 s\u1ea3n xu\u1ea5t. M\u1ed9t nh\u1eadn x\xe9t l\xfd thuy\u1ebft c\u1ea7n \u0111\u01b0\u1ee3c \u0111\u1eb7t v\xe0o \u0111i\u1ec1u ki\u1ec7n l\u1ecbch s\u1eed; n\xf3 kh\xf4ng thay th\u1ebf vi\u1ec7c ki\u1ec3m tra t\u01b0 li\u1ec7u c\u1ee5 th\u1ec3.","M\u1ed9t b\xe0i vi\u1ebft kh\u1eb3ng \u0111\u1ecbnh: \u201cCh\u1ec9 c\u1ea7n \u0111\u1ed5i m\xe1y m\xf3c l\xe0 m\u1ecdi quan h\u1ec7 x\xe3 h\u1ed9i l\u1eadp t\u1ee9c thay \u0111\u1ed5i.\u201d C\xe1ch \u0111\xe1nh gi\xe1 n\xe0o th\u1eadn tr\u1ecdng nh\u1ea5t?",0,A.a(["M\u1ed9t y\u1ebfu t\u1ed1 kh\xf4ng \u0111\u1ee7 ch\u1ee9ng minh to\xe0n b\u1ed9 chu\u1ed7i nh\xe2n qu\u1ea3.","M\u1ed9t v\xed d\u1ee5 lu\xf4n ch\u1ee9ng minh \u0111\u01b0\u1ee3c quy lu\u1eadt cho m\u1ecdi x\xe3 h\u1ed9i.","Ph\xe2n t\xedch x\xe3 h\u1ed9i kh\xf4ng c\u1ea7n b\u1eb1ng ch\u1ee9ng."],f),n,l,o,"\u0110\u1ecdc bi\u1ebfn \u0111\u1ed5i x\xe3 h\u1ed9i trong b\u1ed1i c\u1ea3nh"),A.J(1,A.a(["\u201cM\u1ecdi ng\u01b0\u1eddi \u0111\u1ec1u ph\u1ea3i \u0111\u1ed3ng \xfd.\u201d","\u201cL\xeanin l\u1eadp lu\u1eadn r\u1eb1ng\u2026; c\u1ea7n \u0111\u1ed1i chi\u1ebfu l\u1eadp lu\u1eadn v\u1edbi b\u1ed1i c\u1ea3nh v\xe0 b\u1eb1ng ch\u1ee9ng\u2026\u201d","\u201cKh\xf4ng c\u1ea7n \u0111\u1ecdc b\u1ea3n g\u1ed1c v\xec \u0111\xe3 bi\u1ebft t\xean h\u1ecdc thuy\u1ebft.\u201d"],f),o,"D\u1eabn \u0111\xfang t\xe1c gi\u1ea3, th\u1eddi \u0111i\u1ec3m v\xe0 lu\u1eadn \u0111i\u1ec3m gi\xfap ng\u01b0\u1eddi \u0111\u1ecdc ki\u1ec3m tra ngu\u1ed3n. Ph\xe2n bi\u1ec7t m\xf4 t\u1ea3 v\u1edbi \u0111\xe1nh gi\xe1 l\xe0 k\u1ef9 n\u0103ng \u0111\u1ecdc ph\xea ph\xe1n c\xf3 th\u1ec3 \xe1p d\u1ee5ng cho m\u1ecdi h\u1ecdc thuy\u1ebft.","T\xecm c\xe1ch tr\xecnh b\xe0y v\u1eeba trung th\xe0nh v\u1edbi ngu\u1ed3n, v\u1eeba cho ph\xe9p ng\u01b0\u1eddi \u0111\u1ecdc \u0111\xe1nh gi\xe1 l\u1eadp lu\u1eadn.","marxism-source-reading","M\u1ed9t v\u0103n b\u1ea3n l\xfd lu\u1eadn v\u1eeba c\xf3 kh\xe1i ni\u1ec7m, l\u1eadp lu\u1eadn, v\u1eeba c\xf3 b\u1ed1i c\u1ea3nh v\xe0 l\u1eadp tr\u01b0\u1eddng c\u1ee7a t\xe1c gi\u1ea3. Hi\u1ec3u ch\xednh x\xe1c l\u1eadp lu\u1eadn kh\xf4ng c\xf3 ngh\u0129a l\xe0 ph\u1ea3i \u0111\u1ed3ng \xfd v\u1edbi m\u1ecdi k\u1ebft lu\u1eadn c\u1ee7a t\xe1c gi\u1ea3.","Khi tr\xecnh b\xe0y quan \u0111i\u1ec3m c\u1ee7a L\xeanin trong b\xe0i n\u0103m 1913, c\xe1ch vi\u1ebft n\xe0o ph\xe2n bi\u1ec7t r\xf5 ngu\u1ed3n v\u1edbi nh\u1eadn \u0111\u1ecbnh c\u1ee7a ng\u01b0\u1eddi h\u1ecdc?",0,A.a(["N\xeau ngu\u1ed3n v\xe0 ph\xe2n bi\u1ec7t m\xf4 t\u1ea3 h\u1ecdc thuy\u1ebft v\u1edbi \u0111\xe1nh gi\xe1 c\u1ee7a m\xecnh.","T\xean t\xe1c gi\u1ea3 \u0111\u1ee7 \u0111\u1ec3 thay th\u1ebf b\u1eb1ng ch\u1ee9ng.","Hi\u1ec3u m\u1ed9t h\u1ecdc thuy\u1ebft t\u1ee9c l\xe0 t\xe1n th\xe0nh to\xe0n b\u1ed9."],f),p,k,o,"\u0110\u1ecdc h\u1ecdc thuy\u1ebft c\xf3 \u0111\u1ed1i chi\u1ebfu")],e),c=u.t,b=A.a([4280427042,4287137928,4293848814],c)
b=A.J(1,A.a(["S\u1eafc m\xe0u t\u1eeb \u0111\u1ecf sang xanh.","S\u1eafc \u0111\u1ed9.","S\u1ed1 l\u01b0\u1ee3ng v\u1eadt th\u1ec3."],f),o,"Ba \xf4 t\u1ea1o m\u1ed9t thang s\u1eafc \u0111\u1ed9. Khi d\u1ef1ng h\xecnh kh\u1ed1i, ph\xe2n bi\u1ec7t v\xf9ng s\xe1ng v\xe0 v\xf9ng t\u1ed1i th\u01b0\u1eddng h\u1eefu \xedch tr\u01b0\u1edbc khi th\xeam m\xe0u.","H\xe3y t\u01b0\u1edfng t\u01b0\u1ee3ng ch\u1ee5p ba \xf4 b\u1eb1ng \u1ea3nh \u0111en tr\u1eafng.","painting-value","S\u1eafc \u0111\u1ed9 (value) l\xe0 m\u1ee9c s\xe1ng t\u1ed1i c\u1ee7a m\xe0u. S\u1eafc m\xe0u (hue) l\xe0 t\xean m\xe0u nh\u01b0 \u0111\u1ecf, xanh; \u0111\u1ed9 b\xe3o h\xf2a m\xf4 t\u1ea3 m\u1ee9c r\u1ef1c hay x\u1ec9n. M\u1ed9t tranh c\xf3 th\u1ec3 gi\u1eef c\u1ea5u tr\xfac s\xe1ng t\u1ed1i ngay c\u1ea3 khi chuy\u1ec3n sang thang x\xe1m.","Ba \xf4 t\u1eeb tr\xe1i sang ph\u1ea3i chuy\u1ec3n t\u1eeb t\u1ed1i \u0111\u1ebfn s\xe1ng. Thu\u1ed9c t\xednh n\xe0o \u0111ang thay \u0111\u1ed5i r\xf5 nh\u1ea5t?",2,A.a(["C\u1ea3 ba \xf4 \u0111\u1ec1u c\xf3 c\xf9ng \u0111\u1ed9 s\xe1ng.","M\xe0u x\xe1m kh\xf4ng th\u1ec3 c\xf3 s\u1eafc \u0111\u1ed9.","Kh\xe1c bi\u1ec7t ch\xednh l\xe0 l\u01b0\u1ee3ng s\xe1ng t\u1ed1i, d\xf9 kh\xf4ng c\xf3 s\u1eafc m\xe0u r\u1ef1c."],f),j,q,b,"S\u1eafc \u0111\u1ed9 tr\u01b0\u1edbc m\xe0u s\u1eafc")
s=A.J(2,A.a(["Gi\u1eef m\u1ecdi \u0111i\u1ec3m c\xf9ng \u0111\u1ed9 s\xe1ng.","Ch\u1ec9 vi\u1ebft ch\u1eef \u201cqu\u1ea3 c\u1ea7u\u201d.","\u0110\u1eb7t v\xf9ng s\xe1ng ph\xeda tr\xe1i v\xe0 chuy\u1ec3n d\u1ea7n sang t\u1ed1i ph\xeda ph\u1ea3i."],f),o,"S\u1ef1 chuy\u1ec3n s\u1eafc g\u1ee3i b\u1ec1 m\u1eb7t cong. V\u1ecb tr\xed v\xf9ng s\xe1ng ph\u1ee5 thu\u1ed9c ngu\u1ed3n s\xe1ng; kh\xf4ng c\xf3 quy t\u1eafc m\u1ecdi v\u1eadt \u0111\u1ec1u s\xe1ng ho\u1eb7c t\u1ed1i \u1edf c\xf9ng m\u1ed9t ph\xeda.","Quan s\xe1t h\u01b0\u1edbng ngu\u1ed3n s\xe1ng v\xe0 m\u1eb7t kh\u1ed1i quay ra xa ngu\u1ed3n s\xe1ng.","painting-form","Shape l\xe0 h\xecnh c\xf3 hai chi\u1ec1u; form l\xe0 kh\u1ed1i c\xf3 ba chi\u1ec1u ho\u1eb7c c\u1ea3m gi\xe1c ba chi\u1ec1u. Trong tranh, chuy\u1ec3n s\u1eafc v\xe0 b\xf3ng c\xf3 th\u1ec3 g\u1ee3i kh\u1ed1i tr\xean m\u1eb7t ph\u1eb3ng.","B\u1ea1n mu\u1ed1n h\xecnh tr\xf2n tr\xf4ng nh\u01b0 m\u1ed9t qu\u1ea3 c\u1ea7u c\xf3 ngu\u1ed3n s\xe1ng b\xean tr\xe1i. N\xean l\xe0m g\xec?",0,A.a(["Chuy\u1ec3n s\u1eafc m\xf4 t\u1ea3 b\u1ec1 m\u1eb7t quay d\u1ea7n kh\u1ecfi ngu\u1ed3n s\xe1ng.","Vi\u1ec1n tr\xf2n t\u1ef1 ch\u1ee9ng minh v\u1eadt c\xf3 chi\u1ec1u s\xe2u.","M\u1ecdi v\xf9ng t\u1ed1i lu\xf4n ph\u1ea3i n\u1eb1m b\xean tr\xe1i."],f),j,q,o,"T\u1eeb h\xecnh ph\u1eb3ng \u0111\u1ebfn kh\u1ed1i")
r=A.J(0,A.a(["Qu\u1ea3 t\xe1o \u1edf tr\u01b0\u1edbc chi\u1ebfc c\u1ed1c.","Chi\u1ebfc c\u1ed1c ch\u1eafc ch\u1eafn nh\u1ecf h\u01a1n qu\u1ea3 t\xe1o ngo\xe0i \u0111\u1eddi.","Hai v\u1eadt kh\xf4ng c\xf3 quan h\u1ec7 kh\xf4ng gian."],f),o,"Che khu\u1ea5t g\u1ee3i th\u1ee9 t\u1ef1 tr\u01b0\u1edbc\u2013sau. Mu\u1ed1n suy ra k\xedch th\u01b0\u1edbc th\u1eadt c\xf2n c\u1ea7n kho\u1ea3ng c\xe1ch, ph\u1ed1i c\u1ea3nh v\xe0 c\xe1c th\xf4ng tin kh\xe1c.","T\xe1ch v\u1ecb tr\xed t\u01b0\u01a1ng \u0111\u1ed1i trong tranh kh\u1ecfi k\xedch th\u01b0\u1edbc th\u1eadt c\u1ee7a \u0111\u1ed3 v\u1eadt.","painting-space","Kho\u1ea3ng kh\xf4ng trong tranh c\xf3 th\u1ec3 \u0111\u01b0\u1ee3c g\u1ee3i qua ch\u1ed3ng l\u1edbp, t\u1ef7 l\u1ec7 v\xe0 v\u1ecb tr\xed. Khi v\u1eadt A che m\u1ed9t ph\u1ea7n v\u1eadt B, ng\u01b0\u1eddi xem th\u01b0\u1eddng \u0111\u1ecdc A l\xe0 v\u1eadt \u1edf ph\xeda tr\u01b0\u1edbc.","Trong tranh t\u0129nh v\u1eadt, qu\u1ea3 t\xe1o che m\u1ed9t ph\u1ea7n chi\u1ebfc c\u1ed1c. D\u1ea5u hi\u1ec7u n\xe0y g\u1ee3i \u0111i\u1ec1u g\xec?",1,A.a(["V\u1eadt c\xf3 m\xe0u \u1ea5m lu\xf4n n\u1eb1m ph\xeda tr\u01b0\u1edbc.","Che khu\u1ea5t l\xe0 d\u1ea5u hi\u1ec7u v\u1ec1 th\u1ee9 t\u1ef1 tr\u01b0\u1edbc\u2013sau, kh\xf4ng \u0111\u1ee7 suy ra k\xedch th\u01b0\u1edbc th\u1eadt.","V\u1eadt b\u1ecb che lu\xf4n nh\u1ecf h\u01a1n ngo\xe0i \u0111\u1eddi."],f),j,m,o,"T\u1ea1o chi\u1ec1u s\xe2u b\u1eb1ng che khu\u1ea5t")
c=A.a([4281348144,4294309365,4281348144],c)
return A.d(["marxism",d,"painting",A.a([b,s,r,A.J(1,A.a(["L\xe0m m\u1ecdi v\xf9ng s\xe1ng b\u1eb1ng nhau.","Gi\u1eef chi\u1ebfc c\u1ed1c s\xe1ng v\xe0 gi\u1ea3m \u0111\u1ed9 s\xe1ng v\xf9ng n\u1ec1n c\u1ea1nh n\xf3.","Th\xeam nhi\u1ec1u ch\u1eef \u1edf m\u1ecdi g\xf3c."],f),o,"\u0110i\u1ec3m nh\u1ea5n c\xf3 t\xednh t\u01b0\u01a1ng \u0111\u1ed1i. T\u0103ng ch\xeanh l\u1ec7ch s\u1eafc \u0111\u1ed9 gi\u1eefa ch\u1ee7 th\u1ec3 v\xe0 v\xf9ng n\u1ec1n l\xe2n c\u1eadn l\xe0 m\u1ed9t c\xe1ch h\u01b0\u1edbng m\u1eaft ng\u01b0\u1eddi xem.","So s\xe1nh chi\u1ebfc c\u1ed1c v\u1edbi v\xf9ng n\u1ec1n ngay c\u1ea1nh, thay v\xec ch\u1ec9 nh\xecn ri\xeang chi\u1ebfc c\u1ed1c.","painting-emphasis","Nh\u1ea5n m\u1ea1nh gi\xfap m\u1ed9t v\xf9ng thu h\xfat s\u1ef1 ch\xfa \xfd. T\u01b0\u01a1ng ph\u1ea3n s\xe1ng t\u1ed1i, k\xedch th\u01b0\u1edbc ho\u1eb7c m\xe0u c\xf3 th\u1ec3 t\u1ea1o \u0111i\u1ec3m nh\u1ea5n; hi\u1ec7u qu\u1ea3 ph\u1ee5 thu\u1ed9c nh\u1eefng g\xec bao quanh v\xf9ng \u0111\xf3.","Mu\u1ed1n m\u1ed9t chi\u1ebfc c\u1ed1c s\xe1ng th\xe0nh \u0111i\u1ec3m nh\u1ea5n tr\xean n\u1ec1n t\u1ed1i, thay \u0111\u1ed5i n\xe0o tr\u1ef1c ti\u1ebfp t\u0103ng t\u01b0\u01a1ng ph\u1ea3n s\u1eafc \u0111\u1ed9?",2,A.a(["\u0110i\u1ec3m nh\u1ea5n c\u1ea7n m\u1ecdi chi ti\u1ebft c\xf3 c\xf9ng m\u1ee9c n\u1ed5i b\u1eadt.","C\xe0ng nhi\u1ec1u v\u1eadt th\u1ec3 th\xec t\u01b0\u01a1ng ph\u1ea3n c\xe0ng l\u1edbn.","Ch\xeanh l\u1ec7ch s\xe1ng t\u1ed1i gi\u1eefa c\u1ed1c v\xe0 n\u1ec1n l\xe0m v\xf9ng \u0111\xf3 n\u1ed5i b\u1eadt."],f),j,m,c,"Thi\u1ebft k\u1ebf \u0111i\u1ec3m nh\u1ea5n"),A.J(0,A.a(["L\u1eb7p v\xe0 bi\u1ebfn \u0111\u1ed5i t\u1ea1o nh\u1ecbp d\u1eabn m\u1eaft.","Kh\xf4ng c\xf3 m\u1eabu h\xecnh v\xec c\xe1c n\xe9t kh\xf4ng gi\u1ed1ng h\u1ec7t nhau.","B\u1ed1 c\u1ee5c ch\u1ec9 ph\u1ee5 thu\u1ed9c t\xean m\xe0u."],f),o,"N\xe9t cong \u0111\u01b0\u1ee3c l\u1eb7p l\u1ea1i, c\xf2n k\xedch th\u01b0\u1edbc thay \u0111\u1ed5i c\xf3 t\u1ed5 ch\u1ee9c. S\u1ef1 ph\u1ed1i h\u1ee3p \u0111\xf3 c\xf3 th\u1ec3 t\u1ea1o nh\u1ecbp v\xe0 h\u01b0\u1edbng quan s\xe1t.","T\xecm y\u1ebfu t\u1ed1 \u0111\u01b0\u1ee3c gi\u1eef l\u1ea1i v\xe0 thu\u1ed9c t\xednh thay \u0111\u1ed5i d\u1ea7n.","painting-rhythm","S\u1ef1 l\u1eb7p l\u1ea1i t\u1ea1o m\u1eabu h\xecnh; nh\u1ecbp \u0111i\u1ec7u th\u1ecb gi\xe1c c\xf3 th\u1ec3 xu\u1ea5t hi\u1ec7n khi c\xe1c y\u1ebfu t\u1ed1 l\u1eb7p l\u1ea1i v\xe0 bi\u1ebfn \u0111\u1ed5i c\xf3 t\u1ed5 ch\u1ee9c. Nh\u1ecbp \u0111i\u1ec7u gi\xfap d\u1eabn m\u1eaft qua b\u1ed1 c\u1ee5c.","M\u1ed9t d\xe3y n\xe9t cong l\u1eb7p l\u1ea1i, t\u0103ng d\u1ea7n k\xedch th\u01b0\u1edbc v\u1ec1 ph\xeda ch\u1ee7 th\u1ec3. M\xf4 t\u1ea3 n\xe0o s\xe1t nh\u1ea5t?",1,A.a(["Nh\u1ecbp \u0111i\u1ec7u b\u1eaft bu\u1ed9c m\u1ecdi n\xe9t ph\u1ea3i b\u1eb1ng nhau.","C\xf3 y\u1ebfu t\u1ed1 l\u1eb7p l\u1ea1i v\xe0 m\u1ed9t quy lu\u1eadt bi\u1ebfn \u0111\u1ed5i c\xf3 th\u1ec3 quan s\xe1t.","Ch\u1ec9 tranh c\xf3 \xe2m thanh m\u1edbi c\xf3 nh\u1ecbp \u0111i\u1ec7u."],f),j,l,o,"Nh\u1ecbp \u0111i\u1ec7u v\xe0 bi\u1ebfn \u0111\u1ed5i"),A.J(2,A.a(["\u201cTranh n\xe0y ch\u1eafc ch\u1eafn khi\u1ebfn m\u1ecdi ng\u01b0\u1eddi vui.\u201d","\u201cH\u1ecda s\u0129 h\u1eb3n \u0111ang v\u1ed9i.\u201d","\u201cC\xe1c \u0111\u01b0\u1eddng ch\xe9o l\u1eb7p l\u1ea1i d\u1eabn m\u1eaft t\u1eeb g\xf3c d\u01b0\u1edbi l\xean ph\xeda tr\xean.\u201d"],f),o,"\u0110\u01b0\u1eddng ch\xe9o v\xe0 s\u1ef1 l\u1eb7p l\u1ea1i l\xe0 b\u1eb1ng ch\u1ee9ng h\xecnh th\u1ee9c. Ch\xfang h\u1ed7 tr\u1ee3 c\xe1ch \u0111\u1ecdc v\u1ec1 chuy\u1ec3n \u0111\u1ed9ng, nh\u01b0ng kh\xf4ng ch\u1ee9ng minh m\u1ecdi ng\u01b0\u1eddi \u0111\u1ec1u c\xf3 c\u1ea3m x\xfac gi\u1ed1ng nhau.","Ch\u1ecdn c\xe2u m\xf4 t\u1ea3 chi ti\u1ebft nh\xecn th\u1ea5y \u0111\u01b0\u1ee3c tr\u01b0\u1edbc khi suy \u0111o\xe1n \xfd \u0111\u1ecbnh t\xe1c gi\u1ea3.","painting-critique","Ph\xe2n t\xedch h\xecnh th\u1ee9c b\u1eaft \u0111\u1ea7u t\u1eeb d\u1ea5u hi\u1ec7u c\xf3 th\u1ec3 quan s\xe1t: \u0111\u01b0\u1eddng n\xe9t, s\u1eafc \u0111\u1ed9, m\xe0u, kh\u1ed1i v\xe0 kh\xf4ng gian. C\u1ea7n ph\xe2n bi\u1ec7t \u0111i\u1ec1u nh\xecn th\u1ea5y v\u1edbi suy lu\u1eadn v\u1ec1 \xfd \u0111\u1ecbnh c\u1ee7a h\u1ecda s\u0129.","Nh\u1eadn x\xe9t n\xe0o c\xf3 b\u1eb1ng ch\u1ee9ng th\u1ecb gi\xe1c r\xf5 nh\u1ea5t cho c\u1ea3m gi\xe1c chuy\u1ec3n \u0111\u1ed9ng?",0,A.a(["Nh\u1eadn x\xe9t ch\u1ec9 ra h\u01b0\u1edbng v\xe0 s\u1ef1 l\u1eb7p l\u1ea1i c\u1ee7a \u0111\u01b0\u1eddng n\xe9t c\xf3 th\u1ec3 ki\u1ec3m tra.","C\xf3 th\u1ec3 suy ra t\xe2m tr\u1ea1ng t\xe1c gi\u1ea3 ch\u1ec9 t\u1eeb t\xean tranh.","C\u1ea3m nh\u1eadn c\xe1 nh\xe2n kh\xf4ng bao gi\u1edd c\u1ea7n gi\u1ea3i th\xedch."],f),j,k,o,"Nh\u1eadn x\xe9t tranh b\u1eb1ng b\u1eb1ng ch\u1ee9ng")],e),"coding",A.a([A.J(1,A.a(["6","10","8"],f),"x = 3\nx = x + 2\ny = x * 2\nprint(y)","Sau d\xf2ng hai, x = 5. D\xf2ng ba g\xe1n y = 10 n\xean print(y) in 10.","L\u1eadp b\u1ea3ng x: 3 \u2192 5, r\u1ed3i m\u1edbi t\xednh y.","coding-variable-trace","Ph\xe9p g\xe1n l\u01b0u gi\xe1 tr\u1ecb v\xe0o t\xean bi\u1ebfn. Bi\u1ec3u th\u1ee9c \u1edf v\u1ebf ph\u1ea3i \u0111\u01b0\u1ee3c t\xednh tr\u01b0\u1edbc khi c\u1eadp nh\u1eadt bi\u1ebfn \u1edf v\u1ebf tr\xe1i. H\xe3y ghi l\u1ea1i gi\xe1 tr\u1ecb sau m\u1ed7i d\xf2ng \u0111\u1ec3 \u0111\u1ecdc m\xe3 ch\xednh x\xe1c.","\u0110o\u1ea1n Python in ra s\u1ed1 n\xe0o?",2,A.a(["x v\u1eabn gi\u1eef 3 sau m\u1ecdi ph\xe9p g\xe1n.","Python th\u1ef1c hi\u1ec7n c\xe1c d\xf2ng theo th\u1ee9 t\u1ef1 ng\u01b0\u1ee3c.","x \u0111\u01b0\u1ee3c c\u1eadp nh\u1eadt th\xe0nh 5 tr\u01b0\u1edbc khi t\xednh y = 5 * 2."],f),i,"N\u1ec1n t\u1ea3ng Python",o,"Theo d\xf5i bi\u1ebfn t\u1eebng d\xf2ng"),A.J(0,A.a(["\u0110\u1ea1t","Ch\u01b0a \u0111\u1ea1t","In c\u1ea3 hai d\xf2ng"],f),'score = 5\nif score >= 5:\n    print("\u0110\u1ea1t")\nelse:\n    print("Ch\u01b0a \u0111\u1ea1t")',"D\u1ea5u b\u1eb1ng n\u1eb1m trong >=. \u0110i\u1ec1u ki\u1ec7n \u0111\xfang t\u1ea1i 5, v\xec v\u1eady ch\u01b0\u01a1ng tr\xecnh in \u201c\u0110\u1ea1t\u201d v\xe0 b\u1ecf qua else.","Ph\xe2n bi\u1ec7t > v\u1edbi >=.","coding-branch-boundary","To\xe1n t\u1eed >= bao g\u1ed3m gi\xe1 tr\u1ecb b\u1eb1ng ng\u01b0\u1ee1ng. Trong if/else, ch\u1ec9 nh\xe1nh ph\xf9 h\u1ee3p \u0111i\u1ec1u ki\u1ec7n \u0111\u01b0\u1ee3c th\u1ef1c hi\u1ec7n. Gi\xe1 tr\u1ecb \u0111\xfang b\u1eb1ng ng\u01b0\u1ee1ng l\xe0 m\u1ed9t ca ki\u1ec3m th\u1eed quan tr\u1ecdng.","Khi score = 5, ch\u01b0\u01a1ng tr\xecnh in g\xec?",1,A.a([">= ch\u1ec9 nh\u1eadn c\xe1c s\u1ed1 l\u1edbn h\u01a1n 5.","5 >= 5 \u0111\xfang n\xean ch\u1ec9 th\u1ef1c hi\u1ec7n nh\xe1nh if.","else lu\xf4n ch\u1ea1y sau if."],f),i,h,o,"\u0110i\u1ec1u ki\u1ec7n \u1edf ranh gi\u1edbi"),A.J(2,A.a(["10","4","6"],f),"total = 0\nfor n in range(1, 4):\n    total = total + n\nprint(total)","Ba l\u1ea7n c\u1eadp nh\u1eadt l\xe0 0 + 1 = 1, 1 + 2 = 3, 3 + 3 = 6. Kh\xf4ng c\xf3 v\xf2ng n = 4.","Li\u1ec7t k\xea c\xe1c gi\xe1 tr\u1ecb n tr\u01b0\u1edbc, r\u1ed3i c\u1ed9ng l\u1ea7n l\u01b0\u1ee3t.","coding-loop-accumulator","range(1, 4) t\u1ea1o c\xe1c s\u1ed1 1, 2, 3; c\u1eadn cu\u1ed1i 4 kh\xf4ng \u0111\u01b0\u1ee3c l\u1ea5y. Bi\u1ebfn t\xedch l\u0169y gi\u1eef k\u1ebft qu\u1ea3 qua c\xe1c v\xf2ng l\u1eb7p.","Gi\xe1 tr\u1ecb total cu\u1ed1i c\xf9ng l\xe0 bao nhi\xeau?",0,A.a(["total l\u1ea7n l\u01b0\u1ee3t l\xe0 1, 3, 6 khi n l\xe0 1, 2, 3.","range lu\xf4n bao g\u1ed3m c\u1eadn cu\u1ed1i.","M\u1ed7i v\xf2ng l\u1eb7p \u0111\u1eb7t total v\u1ec1 0."],f),i,h,o,"V\xf2ng l\u1eb7p v\xe0 bi\u1ebfn t\xedch l\u0169y"),A.J(1,A.a(["[1, 2]","[1, 2, 3]","[3]"],f),"a = [1, 2]\nb = a\nb.append(3)\nprint(a)","append thay \u0111\u1ed5i ch\xednh danh s\xe1ch d\xf9ng chung, v\xec v\u1eady a l\xe0 [1, 2, 3]. V\u1edbi v\xed d\u1ee5 c\xe1c s\u1ed1 n\xe0y, b = a.copy() s\u1ebd t\xe1ch danh s\xe1ch tr\u01b0\u1edbc khi append.","V\u1ebd hai m\u0169i t\xean a v\xe0 b t\u1edbi c\xf9ng m\u1ed9t h\u1ed9p danh s\xe1ch.","coding-list-alias","G\xe1n b = a v\u1edbi danh s\xe1ch kh\xf4ng t\u1ea1o b\u1ea3n sao. Hai t\xean c\xf9ng tham chi\u1ebfu m\u1ed9t \u0111\u1ed1i t\u01b0\u1ee3ng. a.copy() c\xf3 th\u1ec3 t\u1ea1o b\u1ea3n sao n\xf4ng khi c\u1ea7n m\u1ed9t danh s\xe1ch kh\xe1c.","Sau \u0111o\u1ea1n m\xe3, a c\xf3 gi\xe1 tr\u1ecb n\xe0o?",2,A.a(["b = a t\u1ea1o b\u1ea3n sao \u0111\u1ed9c l\u1eadp.","append thay th\u1ebf to\xe0n b\u1ed9 danh s\xe1ch.","a v\xe0 b tr\u1ecf t\u1edbi c\xf9ng danh s\xe1ch n\xean thay \u0111\u1ed5i qua b c\u0169ng th\u1ea5y qua a."],f),i,g,o,"Hai t\xean, m\u1ed9t danh s\xe1ch"),A.J(0,A.a(["9","8","5"],f),"def double(n):\n    return n * 2\n\nresult = double(4) + 1\nprint(result)","double(4) tr\u1ea3 8. result = 8 + 1 = 9; ch\u1ec9 print(result) t\u1ea1o \u0111\u1ea7u ra trong \u0111o\u1ea1n m\xe3 n\xe0y.","Thay l\u1eddi g\u1ecdi double(4) b\u1eb1ng gi\xe1 tr\u1ecb n\xf3 tr\u1ea3 v\u1ec1.","coding-function-return","return g\u1eedi k\u1ebft qu\u1ea3 t\u1eeb h\xe0m v\u1ec1 n\u01a1i g\u1ecdi. Bi\u1ebfn tham s\u1ed1 nh\u1eadn \u0111\u1ed1i s\u1ed1 cho l\u1ea7n g\u1ecdi \u0111\xf3. Ph\xe2n bi\u1ec7t vi\u1ec7c t\xednh gi\xe1 tr\u1ecb v\u1edbi vi\u1ec7c in gi\xe1 tr\u1ecb ra m\xe0n h\xecnh.","Ch\u01b0\u01a1ng tr\xecnh in s\u1ed1 n\xe0o?",0,A.a(["H\xe0m tr\u1ea3 8 cho n\u01a1i g\u1ecdi; bi\u1ec3u th\u1ee9c b\xean ngo\xe0i c\u1ed9ng th\xeam 1.","return t\u1ef1 in 8 v\xe0 b\u1ecf qua ph\xe9p c\u1ed9ng.","Tham s\u1ed1 n lu\xf4n b\u1eb1ng 2."],f),i,g,o,"Gi\xe1 tr\u1ecb tr\u1ea3 v\u1ec1 c\u1ee7a h\xe0m"),A.J(2,A.a(["age = 25, mong \u0111\u1ee3i True","age = 17, mong \u0111\u1ee3i False","age = 18, mong \u0111\u1ee3i True"],f),"def eligible(age):\n    return age > 18","H\xe0m hi\u1ec7n tr\u1ea3 False t\u1ea1i tu\u1ed5i 18. S\u1eeda \u0111i\u1ec1u ki\u1ec7n th\xe0nh age >= 18 v\xe0 ki\u1ec3m tra l\u1ea1i c\xe1c ca 17, 18, 19 \u0111\u1ec3 bao ph\u1ee7 ranh gi\u1edbi.","Th\u1eed gi\xe1 tr\u1ecb \u0111\xfang b\u1eb1ng ng\u01b0\u1ee1ng \u0111\u01b0\u1ee3c nh\u1eafc trong y\xeau c\u1ea7u.","coding-test-boundaries","Ki\u1ec3m th\u1eed ph\u1ea3i \u0111\u1ed1i chi\u1ebfu y\xeau c\u1ea7u. V\u1edbi y\xeau c\u1ea7u \u201ct\u1eeb 18 tu\u1ed5i\u201d, c\xe1c gi\xe1 tr\u1ecb d\u01b0\u1edbi ng\u01b0\u1ee1ng, \u0111\xfang ng\u01b0\u1ee1ng v\xe0 tr\xean ng\u01b0\u1ee1ng gi\xfap ph\xe1t hi\u1ec7n sai l\u1ec7ch \u1edf ranh gi\u1edbi.","H\xe0m ph\u1ea3i tr\u1ea3 True t\u1eeb 18 tu\u1ed5i. Ca n\xe0o tr\u1ef1c ti\u1ebfp ph\xe1t hi\u1ec7n l\u1ed7i c\u1ee7a \u0111o\u1ea1n m\xe3?",1,A.a(["M\u1ecdi gi\xe1 tr\u1ecb tr\xean 18 \u0111\u1ec1u g\xe2y l\u1ed7i.","18 > 18 l\xe0 False, tr\xe1i y\xeau c\u1ea7u bao g\u1ed3m tu\u1ed5i 18.","Kh\xf4ng th\u1ec3 ki\u1ec3m th\u1eed h\xe0m c\xf3 tham s\u1ed1."],f),i,"Th\u1eed th\xe1ch Python",o,"Ch\u1ecdn ki\u1ec3m th\u1eed b\u1eaft l\u1ed7i")],e)],u.N,u.X)})
t($,"jt","fL",()=>{var s,r,q,p,o,n,m=A.a([],u.p)
for(s=u.S,r=u.t,q=1;q<=4;++q)for(p=1;p<=4;++p)for(o=1;o<=4;++o)for(n=1;n<=4;++n)if(A.hd([q,p,o,n],s).a===4)m.push(A.a([q,p,o,n],r))
return m})
t($,"jw","ez",()=>{var s=null,r="Kh\xe1m ph\xe1",q=u.t,p=u.N,o=u.z,n=A.bp("A<k>"),m=u.J,l=u.s
return A.d(["geometry",A.a([A.p(B.c,1,s,"Di\u1ec7n t\xedch h\xecnh ch\u1eef nh\u1eadt b\u1eb1ng chi\u1ec1u d\xe0i nh\xe2n chi\u1ec1u r\u1ed9ng: 3 \xd7 2 = 6.","Th\u1eed m\u1ed9t c\u1ea1nh d\xe0i 3 \xf4 v\xe0 m\u1ed9t c\u1ea1nh d\xe0i 2 \xf4.","geometry-rectangle",A.d(["points",A.a([A.a([0,0],q),A.a([4,0],q),A.a([4,4],q),A.a([0,4],q)],u.p)],p,o),"polygonVertices","Di chuy\u1ec3n b\u1ed1n \u0111\u1ec9nh \u0111\u1ec3 t\u1ea1o h\xecnh ch\u1eef nh\u1eadt c\xf3 di\u1ec7n t\xedch 6 \xf4 vu\xf4ng.",B.b,r,"K\xe9o ra di\u1ec7n t\xedch",new A.db()),A.p(B.c,1,s,"Ph\xe9p \u0111\u1ed1i x\u1ee9ng gi\u1eef nguy\xean h\xe0ng v\xe0 \u0111\u1ea3o v\u1ecb tr\xed c\u1ed9t qua tr\u1ee5c.","M\u1ed7i \xf4 \u1ea3nh c\xe1ch tr\u1ee5c m\u1ed9t kho\u1ea3ng b\u1eb1ng \xf4 g\u1ed1c.","geometry-mirror",A.d(["cells",A.a([],q)],p,o),"symmetryMirror","Ch\u1ea1m c\xe1c \xf4 b\xean ph\u1ea3i \u0111\u1ec3 ph\u1ea3n chi\u1ebfu h\xecnh xanh qua tr\u1ee5c gi\u1eefa.",B.b,r,"X\u01b0\u1edfng \u0111\u1ed1i x\u1ee9ng",new A.dc()),A.p(B.c,1,s,"Hai tam gi\xe1c vu\xf4ng b\u1eb1ng nhau gh\xe9p d\u1ecdc c\u1ea1nh huy\u1ec1n t\u1ea1o th\xe0nh h\xecnh vu\xf4ng.","Hai c\u1ea1nh huy\u1ec1n ph\u1ea3i tr\xf9ng nhau, hai g\xf3c vu\xf4ng n\u1eb1m \u1edf hai g\xf3c \u0111\u1ed1i di\u1ec7n.","geometry-tangram",A.d(["turns",A.a([1,1],q),"placed",A.a([!1,!1],n)],p,o),"tangramRotate","Xoay hai tam gi\xe1c, r\u1ed3i k\xe9o t\u1eebng m\u1ea3nh v\xe0o khung \u0111\u1ec3 gh\xe9p th\xe0nh h\xecnh vu\xf4ng.",B.b,r,"Hai m\u1ea3nh th\xe0nh vu\xf4ng",new A.dd())],m),"coding",A.a([A.p(B.c,1,s,"M\u1ed9t thu\u1eadt to\xe1n l\xe0 chu\u1ed7i thao t\xe1c r\xf5 r\xe0ng; th\u1ee9 t\u1ef1 l\u1ec7nh quy\u1ebft \u0111\u1ecbnh \u0111\u01b0\u1eddng \u0111i.","\u0110i theo m\xe9p tr\xean r\u1ed3i r\u1ebd xu\u1ed1ng. B\u1ea1n c\xf3 th\u1ec3 x\xf3a l\u1ec7nh \u0111\u1ec3 th\u1eed l\u1ea1i.","coding-route",A.d(["commands",A.a([],l)],p,o),"robotRoute","Vu\u1ed1t tr\xean b\u1ea3n \u0111\u1ed3 ho\u1eb7c th\xeam l\u1ec7nh \u0111\u1ec3 d\u1eabn robot t\u1eeb g\xf3c tr\xe1i tr\xean t\u1edbi ng\xf4i sao. Tr\xe1nh \xf4 \u0111\xe1 \u1edf gi\u1eefa.",B.b,r,"D\u1eabn robot v\u1ec1 nh\xe0",new A.df()),A.p(B.c,1,s,"L\u1eb7p [ph\u1ea3i, xu\u1ed1ng] ba l\u1ea7n t\u1ea1o \u0111\u01b0\u1eddng c\u1ea7u thang t\u1edbi \xf4 (3, 3).","Kh\u1ed1i l\u1eb7p gi\xfap d\xf9ng hai l\u1ec7nh \u0111\u1ec3 t\u1ea1o ra s\xe1u b\u01b0\u1edbc.","coding-loop",A.d(["body",A.a(["D","R"],l),"repeat",1],p,o),"loopBuilder","L\u1eafp hai l\u1ec7nh v\xe0 \u0111\u1eb7t s\u1ed1 l\u1ea7n l\u1eb7p \u0111\u1ec3 robot \u0111i \u0111\xfang c\u1ea7u thang: sang ph\u1ea3i r\u1ed3i xu\u1ed1ng, ba l\u1ea7n.",B.b,r,"C\u1ea7u thang v\xf2ng l\u1eb7p",new A.dg()),A.p(B.c,1,s,"M\u1ed9t m\u1ea1ng s\u1eafp x\u1ebfp d\xf9ng c\xf9ng chu\u1ed7i b\u1ed9 so s\xe1nh cho m\u1ecdi \u0111\u1ea7u v\xe0o. M\u1ed7i b\u1ed9 t\u1ef1 \u0111\u01b0a s\u1ed1 nh\u1ecf l\xean tr\xean; m\u1ea1ng n\xe0y \u0111\xe3 v\u01b0\u1ee3t qua c\u1ea3 24 ho\xe1n v\u1ecb.","M\u1ed7i b\u1ed9 so s\xe1nh ch\u1ec9 \u0111\u1ed5i ch\u1ed7 khi s\u1ed1 tr\xean l\u1edbn h\u01a1n s\u1ed1 d\u01b0\u1edbi. Th\u1eed chu\u1ed7i 1\u20132, 2\u20133, 3\u20134, r\u1ed3i x\u1eed l\xfd ba d\xe2y \u0111\u1ea7u.","coding-sort",A.d(["stages",A.a([],q),"result",A.a([],q)],p,o),"sortingNetwork","L\u1eafp t\u1ed1i \u0111a 6 b\u1ed9 so s\xe1nh gi\u1eefa c\xe1c d\xe2y k\u1ec1 nhau, r\u1ed3i ch\u1ea1y m\xe1y. M\u1ea1ng c\u1ea7n s\u1eafp \u0111\xfang c\u1ea3 24 th\u1ee9 t\u1ef1 \u0111\u1ea7u v\xe0o.",B.b,r,"Thi\u1ebft k\u1ebf m\xe1y s\u1eafp x\u1ebfp",new A.dh())],m),"circuits",A.a([A.p(B.c,1,s,"D\xf2ng \u0111i\u1ec7n c\u1ea7n m\u1ed9t \u0111\u01b0\u1eddng k\xedn t\u1eeb ngu\u1ed3n, qua t\u1ea3i v\xe0 tr\u1edf v\u1ec1 ngu\u1ed3n.","C\u1ea7n d\xe2y 1\u20132 v\xe0 d\xe2y 3\u20134. \u0110\u1eebng n\u1ed1i tr\u1ef1c ti\u1ebfp hai c\u1ef1c ngu\u1ed3n ho\u1eb7c n\u1ed1i t\u1eaft hai \u0111\u1ea7u \u0111\xe8n.","circuits-wire",A.d(["edges",A.a([],l)],p,o),"wireCircuit","\u0110\xe8n v\xe0 ngu\u1ed3n \u0111\xe3 g\u1eafn s\u1eb5n. K\xe9o hai d\xe2y \u0111\u1ec3 n\u1ed1i c\u1ef1c d\u01b0\u01a1ng ngu\u1ed3n t\u1edbi \u0111\u1ea7u v\xe0o \u0111\xe8n, r\u1ed3i n\u1ed1i \u0111\u1ea7u ra \u0111\xe8n v\u1ec1 c\u1ef1c \xe2m.",B.b,r,"\xc1nh s\xe1ng \u0111\u1ea7u ti\xean",new A.di()),A.p(B.c,1,s,"M\u1ea1ch s\xe1ng khi (A HO\u1eb6C B) V\xc0 C. V\u1edbi A m\u1edf, B v\xe0 C \u0111\u1ec1u ph\u1ea3i \u0111\xf3ng.","A v\xe0 B m\u1eafc song song, c\u1ea3 hai c\xf9ng \u0111i qua C.","circuits-logic",A.d(["switches",A.a([!1,!1,!1],n)],p,o),"switchLogic","Nh\xe1nh A \u0111ang b\u1ea3o tr\xec: gi\u1eef A m\u1edf. B\u1eadt \u0111\xe8n b\u1eb1ng nh\xe1nh B v\xe0 c\xf4ng t\u1eafc ch\xednh C.",B.b,r,"\u0110\u01b0\u1eddng \u0111i\u1ec7n d\u1ef1 ph\xf2ng",new A.dj()),A.p(B.c,1,s,"Pha m\xe0u c\u1ed9ng: \u0111\u1ecf + l\u1ee5c = v\xe0ng. \u0110\xe2y l\xe0 \xe1nh s\xe1ng, kh\xe1c pha s\u01a1n.","\xc1nh s\xe1ng \u0111\u1ecf c\u1ed9ng \xe1nh s\xe1ng l\u1ee5c t\u1ea1o v\xe0ng; \xe1nh s\xe1ng lam l\xe0m m\xe0u nh\u1ea1t \u0111i.","circuits-light",A.d(["rgb",A.a([0,0,1],u.n)],p,o),"colorMixer","\u0110i\u1ec1u ch\u1ec9nh ba ch\xf9m s\xe1ng \u0111\u1ec3 t\u1ea1o m\xe0u v\xe0ng c\u1ee7a m\u1eabu.",B.b,r,"Ph\xf2ng pha \xe1nh s\xe1ng",new A.dk())],m),"probability",A.a([A.p(B.c,1,s,"C\xf3 2 k\u1ebft qu\u1ea3 xanh tr\xean 6 vi\xean \u0111\u1ed3ng kh\u1ea3 n\u0103ng: 2/6 = 1/3.","Trong 6 vi\xean, c\u1ea7n 2 vi\xean xanh. C\xe1c vi\xean c\xf2n l\u1ea1i m\xe0u \u0111\u1ecf.","probability-bag",A.d(["balls",A.a([],l)],p,o),"probabilityBag","Th\u1ea3 \u0111\u1ee7 6 vi\xean v\xe0o t\xfai \u0111\u1ec3 x\xe1c su\u1ea5t r\xfat m\u1ed9t vi\xean xanh l\xe0 1/3.",B.b,r,"T\xfai b\xed m\u1eadt",new A.dl()),A.p(B.c,1,s,"Kh\xf4ng gian m\u1eabu g\u1ed3m SS, SN, NS, NN. B\u1ed1n k\u1ebft qu\u1ea3 c\xf3 x\xe1c su\u1ea5t b\u1eb1ng nhau v\u1edbi xu c\xe2n \u0111\u1ed1i.","SN kh\xe1c NS v\xec \u0111\u1ed3ng th\u1ee9 nh\u1ea5t v\xe0 \u0111\u1ed3ng th\u1ee9 hai \u0111\u01b0\u1ee3c ph\xe2n bi\u1ec7t.","probability-space",A.d(["outcomes",A.a([],l)],p,o),"sampleSpace","Gh\xe9p t\u1eebng c\u1eb7p m\u1eb7t xu v\xe0o b\u1ea3ng \u0111\u1ec3 li\u1ec7t k\xea \u0111\u1ee7 c\xe1c k\u1ebft qu\u1ea3 khi tung hai \u0111\u1ed3ng xu c\xf3 th\u1ee9 t\u1ef1.",B.b,r,"B\u1ea3n \u0111\u1ed3 hai \u0111\u1ed3ng xu",new A.dm()),A.p(B.c,1,s,"X\xe1c su\u1ea5t tr\xfang m\xe0u xanh b\u1eb1ng ph\u1ea7n g\xf3c xanh tr\xean c\u1ea3 v\xf2ng: 3 \xd7 45\xb0 / 360\xb0 = 3/8.","V\xf2ng quay \u0111\u01b0\u1ee3c chia th\xe0nh 8 cung b\u1eb1ng nhau; c\u1ea7n 3 cung xanh.","probability-spinner",A.d(["sectors",1],p,o),"probabilitySpinner","K\xe9o tay n\u1eafm \u0111\u1ec3 ph\u1ea7n m\xe0u xanh chi\u1ebfm 3/8 v\xf2ng quay.",B.b,r,"Thi\u1ebft k\u1ebf v\xf2ng quay",new A.de())],m)],p,u.X)})
t($,"jx","fN",()=>{var s="Th\u1eed th\xe1ch",r=A.a(["fractions.part-whole"],u.s),q=u.N,p=u.z,o=u.J
return A.d(["math",A.a([A.p(B.c,2,A.iH(),"3/4 = 6/8. Ph\xe2n s\u1ed1 bi\u1ec3u di\u1ec5n m\u1ed9t v\u1ecb tr\xed tr\xean tr\u1ee5c s\u1ed1, kh\xf4ng ch\u1ec9 l\xe0 ph\u1ea7n t\xf4 c\u1ee7a chi\u1ebfc b\xe1nh.","Chia \u0111o\u1ea1n th\xe0nh 4 ph\u1ea7n b\u1eb1ng nhau r\u1ed3i \u0111i 3 ph\u1ea7n. Hai n\u1ea5c nh\u1ecf t\u1ea1o m\u1ed9t ph\u1ea7n t\u01b0.","math-number-line",A.d(["position",0],q,p),"fractionNumberLine","\u0110\u1eb7t \u0111i\u1ec3m t\u1ea1i 3/4 \u0111o\u1ea1n \u0111\u01b0\u1eddng t\u1eeb 0 \u0111\u1ebfn 1. M\u1ed7i n\u1ea5c l\xe0 1/8.",r,"V\u1eadn d\u1ee5ng","Ph\xe2n s\u1ed1 c\xf3 m\u1ed9t v\u1ecb tr\xed",new A.dp())],o),"logic",A.a([A.p(B.c,1,null,"A s\xe1ng v\xe0 B t\u1eaft l\xe0 ph\u1ea3n v\xed d\u1ee5. Khi A t\u1eaft, tr\u01b0\u1eddng h\u1ee3p \u0111\xf3 kh\xf4ng b\xe1c b\u1ecf m\u1ec7nh \u0111\u1ec1 \u201cn\u1ebfu A th\xec B\u201d.","Mu\u1ed1n b\xe1c b\u1ecf quy t\u1eafc, \u0111i\u1ec1u ki\u1ec7n \u0111\u1ea7u ph\u1ea3i x\u1ea3y ra nh\u01b0ng k\u1ebft lu\u1eadn kh\xf4ng x\u1ea3y ra.","logic-counterexample",A.d(["a",!1,"b",!1],q,p),"logicalCounterexample","C\xf3 ng\u01b0\u1eddi n\xf3i: \u201c\u0110\xe8n A s\xe1ng th\xec \u0111\xe8n B lu\xf4n s\xe1ng\u201d. B\u1eadt/t\u1eaft hai \u0111\xe8n \u0111\u1ec3 t\u1ea1o m\u1ed9t ph\u1ea3n v\xed d\u1ee5.",B.b,s,"M\u1ed9t tr\u01b0\u1eddng h\u1ee3p \u0111\u1ee7 \u0111\u1ec3 b\xe1c b\u1ecf",new A.dq())],o),"data",A.a([A.p(B.c,1,null,"\u0110i\u1ec3m cu\u1ed1i t\u1eeb 10 tr\u1edf l\xean l\xe0m trung b\xecnh \xedt nh\u1ea5t b\u1eb1ng 4, trong khi trung v\u1ecb v\u1eabn l\xe0 3. M\u1ed9t ngo\u1ea1i l\u1ec7 c\xf3 th\u1ec3 k\xe9o trung b\xecnh \u0111i xa.","Trung v\u1ecb l\xe0 \u0111i\u1ec3m th\u1ee9 ba sau s\u1eafp x\u1ebfp. Quan s\xe1t xem \u0111i\u1ec3m cu\u1ed1i \u1ea3nh h\u01b0\u1edfng \u0111\u1ebfn t\u1ed5ng nh\u01b0 th\u1ebf n\xe0o.","data-median-outlier",A.d(["outlier",5],q,p),"outlierExplorer","B\u1ed1n \u0111i\u1ec3m c\u1ed1 \u0111\u1ecbnh l\xe0 1, 2, 3, 4. K\xe9o \u0111i\u1ec3m cu\u1ed1i \u0111\u1ec3 trung b\xecnh l\u1edbn h\u01a1n trung v\u1ecb \xedt nh\u1ea5t 1 \u0111\u01a1n v\u1ecb.",B.b,s,"Khi m\u1ed9t \u0111i\u1ec3m \u0111i xa",new A.dr())],o)],q,u.X)})
t($,"jA","eA",()=>{var s="Th\u1eed th\xe1ch",r=null,q=u.N,p=u.z,o=u.J,n=A.a([A.ej("logic-invariant","Gi\u1eef nguy\xean s\u1ef1 c\xe2n b\u1eb1ng",5,9),A.p(A.d(["target",6],q,p),1,r,"C\xe2n b\u1eb1ng cho th\u1ea5y hai b\xean c\xf3 c\xf9ng kh\u1ed1i l\u01b0\u1ee3ng: h\u1ed9p n\xe0y b\u1eb1ng 6 kh\u1ed1i \u0111\u01a1n v\u1ecb.","D\xf9ng chi\u1ec1u nghi\xeang l\xe0m ph\u1ea3n h\u1ed3i; khi th\xeam qu\xe1 nhi\u1ec1u, h\xe3y l\u1ea5y b\u1edbt.","logic-hidden",A.d(["blocks",1],q,p),"balanceBlocks","H\u1ed9p m\u1edbi c\xf3 kh\u1ed1i l\u01b0\u1ee3ng kh\xe1c tr\u01b0\u1edbc. Th\xeam ho\u1eb7c l\u1ea5y kh\u1ed1i \u0111\u01a1n v\u1ecb \u0111\u1ec3 t\xecm l\xfac c\xe2n n\u1eb1m ngang.",B.b,s,"Hi\u1ec7u chu\u1ea9n h\u1ed9p b\xed m\u1eadt",new A.dB())],o),m=A.a([A.ff("math-equivalent","M\u1ed9t ph\xe2n s\u1ed1, hai c\xe1ch vi\u1ebft","Bi\u1ec3u di\u1ec5n 3/4 chi\u1ebfc b\xe1nh.",6),A.ff("math-complement","T\xecm ph\u1ea7n c\xf2n l\u1ea1i","T\xf4 sao cho ph\u1ea7n CH\u01afA t\xf4 chi\u1ebfm 3/8 chi\u1ebfc b\xe1nh.",5)],o),l=A.a([A.ei("science-distance","C\xf9ng \u0111\xedch, kh\xe1c h\xe0nh tr\xecnh","\u0110i \u0111\xfang 8 m v\xe0 k\u1ebft th\xfac b\u1eb1ng 2 gi\xe2y ngh\u1ec9.",new A.dC()),A.ei("science-return","Ch\u1eadm tr\u01b0\u1edbc, nhanh sau","\u0110i \u0111\xfang 6 m, b\u1eaft \u0111\u1ea7u \u0111i ch\u1eadm v\xe0 k\u1ebft th\xfac \u0111i nhanh.",new A.dD())],o),k=u.t,j=A.a([A.ed("data-outlier","San \u0111\u1ec1u sau m\u1ed9t ngo\u1ea1i l\u1ec7",A.a([1,2,9],k),"L\xe0m ba t\xf2a cao b\u1eb1ng nhau.",A.a([4,4,4],k)),A.ed("data-distribution","C\xf9ng trung b\xecnh, kh\xe1c ph\xe2n b\u1ed1",A.a([4,4,4],k),"Gi\u1eef trung b\xecnh 4 t\u1ea7ng; t\xf2a gi\u1eefa cao 4 t\u1ea7ng, t\xf2a ph\u1ea3i g\u1ea5p ba t\xf2a tr\xe1i.",A.a([2,4,6],k))],o),i=A.a([A.fg("geometry-fence","M\u1ed9t m\u1ea3nh v\u01b0\u1eddn, hai \u0111i\u1ec1u ki\u1ec7n",8,12),A.fg("geometry-square","Khi h\xecnh vu\xf4ng xu\u1ea5t hi\u1ec7n",9,12)],o),h=A.a([A.ek("coding-shortest","Ti\u1ebft ki\u1ec7m t\u1eebng l\u1ec7nh",B.b,r),A.ek("coding-checkpoint","Gh\xe9 tr\u1ea1m tr\u01b0\u1edbc khi v\u1ec1",B.b,A.a([0,2],k))],o),g=A.a([A.fd("circuits-cyan","Tr\u1ed9n ra m\xe0u tr\u1eddi","l\u1ee5c lam",4278255615,A.a([0,1,1],k)),A.fd("circuits-white","T\u1eeb ba m\xe0u th\xe0nh tr\u1eafng","tr\u1eafng",4294967295,A.a([1,1,1],k))],o),f=A.a([A.f7("probability-fair","Thi\u1ebft k\u1ebf m\u1ed9t t\xfai c\xf4ng b\u1eb1ng",8,4,"Hai m\xe0u ph\u1ea3i c\xf3 c\u01a1 h\u1ed9i xu\u1ea5t hi\u1ec7n b\u1eb1ng nhau."),A.f7("probability-odds","C\u01a1 h\u1ed9i g\u1ea5p ba",8,6,"C\u01a1 h\u1ed9i r\xfat xanh ph\u1ea3i g\u1ea5p ba c\u01a1 h\u1ed9i r\xfat \u0111\u1ecf.")],o),e=A.a([A.ej("algebra-isolate","\u1ea8n s\u1ed1 sau nh\u1eefng kh\u1ed1i",2,8),A.ej("algebra-transfer","Thay s\u1ed1, gi\u1eef quy t\u1eafc",4,10),A.ed("algebra-model","Gi\u1ea3i b\u1eb1ng m\u1ed9t th\xe0nh ph\u1ed1",A.a([6,3,3],k),"T\xf2a gi\u1eefa g\u1ea5p \u0111\xf4i t\xf2a tr\xe1i; t\xf2a ph\u1ea3i g\u1ea5p ba t\xf2a tr\xe1i. T\xecm c\u1ea3 ba chi\u1ec1u cao.",A.a([2,4,6],k))],o),d=A.ek("optimization-debug","G\u1ee1 l\u1ed7i \u0111\u01b0\u1eddng \u0111i",A.a(["R","D"],u.s),r)
p=A.d(["stages",A.a([0,1,2],k),"result",A.a([],k)],q,p)
k=$.ez().h(0,"coding")
k.toString
return A.d(["logic",n,"math",m,"science",l,"data",j,"geometry",i,"coding",h,"circuits",g,"probability",f,"algebra",e,"optimization",A.a([d,A.p(B.c,1,r,"M\xe1y \u0111\u01b0\u1ee3c ki\u1ec3m tra tr\xean c\u1ea3 24 ho\xe1n v\u1ecb, kh\xf4ng ch\u1ec9 v\xed d\u1ee5 \u0111ang hi\u1ec3n th\u1ecb. Chu\u1ed7i b\u1ed9 so s\xe1nh d\xf9ng l\u1ea1i \u0111\u01b0\u1ee3c v\u1edbi m\u1ecdi \u0111\u1ea7u v\xe0o.","M\u1ed9t \u0111\u1ea7u v\xe0o ch\u1ea1y \u0111\xfang ch\u01b0a ch\u1ee9ng minh m\xe1y \u0111\xfang. T\xecm c\u1eb7p d\xe2y c\xf2n c\xf3 th\u1ec3 \u0111\u1ea3o th\u1ee9 t\u1ef1 sau m\u1ed7i l\u01b0\u1ee3t.","optimization-network",p,"sortingNetwork","M\xe1y \u0111\xe3 c\xf3 ba b\u1ed9 so s\xe1nh nh\u01b0ng ch\u01b0a s\u1eafp \u0111\xfang m\u1ecdi \u0111\u1ea7u v\xe0o. Ch\u1ec9nh ho\u1eb7c l\u1eafp th\xeam, t\u1ed1i \u0111a 6 b\u1ed9; ch\u1ea1y ki\u1ec3m tra c\u1ea3 24 ho\xe1n v\u1ecb.",B.b,s,"S\u1eeda m\xe1y, kh\xf4ng s\u1eeda \u0111\u1ea7u v\xe0o",B.a.gaI(k).w),A.ei("optimization-budget","Ng\xe2n s\xe1ch chuy\u1ec3n \u0111\u1ed9ng","\u0110i \u0111\xfang 4 m v\u1edbi ch\u1ec9 m\u1ed9t \xf4 \u0111i nhanh; hai \xf4 c\xf2n l\u1ea1i ph\u1ea3i ngh\u1ec9.",new A.dE())],o)],q,u.X)})
t($,"jB","eB",()=>{var s="Kh\xe1m ph\xe1 3D",r="V\u1eadn d\u1ee5ng 3D",q="solidExplorer",p=u.N,o=u.z,n=u.J
return A.d(["geography",A.a([A.p(B.c,1,new A.dO(),"V\u0129 \u0111\u1ed9 \u0111o v\u1ecb tr\xed B\u1eafc\u2013Nam; kinh \u0111\u1ed9 \u0111o v\u1ecb tr\xed \u0110\xf4ng\u2013T\xe2y. Xoay qu\u1ea3 \u0111\u1ecba c\u1ea7u ch\u1ec9 \u0111\u1ed5i g\xf3c nh\xecn, kh\xf4ng \u0111\u1ed5i t\u1ecda \u0111\u1ed9 \u0111i\u1ec3m.","V\u0129 \u0111\u1ed9 B\u1eafc n\u1eb1m ph\xeda b\u1eafc x\xedch \u0111\u1ea1o. Kinh \u0111\u1ed9 \u0110\xf4ng \u0111\u01b0\u1ee3c \u0111o v\u1ec1 ph\xeda \u0111\xf4ng t\u1eeb kinh tuy\u1ebfn g\u1ed1c 0\xb0.","geography-globe-grid",A.d(["latitude",0,"longitude",0],p,o),"globeExplorer","\u0110\u1eb7t \u0111i\u1ec3m t\u1ea1i 15\xb0 B\u1eafc, 105\xb0 \u0110\xf4ng tr\xean qu\u1ea3 \u0111\u1ecba c\u1ea7u. Xoay \u0111\u1ec3 nh\xecn quanh, r\u1ed3i ch\u1ea1m b\u1ec1 m\u1eb7t ho\u1eb7c \u0111i\u1ec1u ch\u1ec9nh t\u1ecda \u0111\u1ed9.",B.b,s,"T\xecm \u0111\u01b0\u1eddng tr\xean qu\u1ea3 \u0111\u1ecba c\u1ea7u",new A.dP()),A.p(B.c,1,new A.dQ(),"T\u1eeb tr\xean xu\u1ed1ng: 10, 20, 30 tri\u1ec7u n\u0103m. M\xf4 h\xecnh gi\u1ea3 \u0111\u1ecbnh c\xe1c l\u1edbp l\u1eafng \u0111\u1ecdng li\xean ti\u1ebfp, ch\u01b0a b\u1ecb bi\u1ebfn d\u1ea1ng ho\u1eb7c \u0111\u1ea3o l\u1ed9n.","Trong chu\u1ed7i tr\u1ea7m t\xedch kh\xf4ng b\u1ecb \u0111\u1ea3o l\u1ed9n, l\u1edbp b\xean d\u01b0\u1edbi h\xecnh th\xe0nh tr\u01b0\u1edbc l\u1edbp ph\u1ee7 l\xean tr\xean.","geography-rock-layers",A.d(["layers",A.a([30,10,20],u.t)],p,o),"strataExplorer","C\xe1c l\u1edbp tr\u1ea7m t\xedch ch\u01b0a b\u1ecb \u0111\u1ea3o l\u1ed9n. S\u1eafp l\u1edbp c\xf3 tu\u1ed5i 10, 20 v\xe0 30 tri\u1ec7u n\u0103m t\u1eeb tr\xean xu\u1ed1ng d\u01b0\u1edbi, theo th\u1ee9 t\u1ef1 h\xecnh th\xe0nh.",B.b,r,"\u0110\u1ecdc l\u1ecbch s\u1eed trong l\u1edbp \u0111\u1ea5t \u0111\xe1",new A.dR())],n),"geometry",A.a([A.p(B.c,1,new A.dS(),"Kh\u1ed1i c\xf3 c\xe1c c\u1ea1nh 2, 2, 3 th\u1ecfa V = 12 v\xe0 S = 2 \xd7 (4 + 6 + 6) = 32. \u0110\u1ed5i h\u01b0\u1edbng kh\u1ed1i kh\xf4ng \u0111\u1ed5i hai \u0111\u1ea1i l\u01b0\u1ee3ng n\xe0y.","Th\u1ec3 t\xedch l\xe0 d\xe0i \xd7 cao \xd7 s\xe2u. Th\u1eed ba k\xedch th\u01b0\u1edbc c\xf3 t\xedch b\u1eb1ng 12 r\u1ed3i so s\xe1nh t\u1ed5ng di\u1ec7n t\xedch s\xe1u m\u1eb7t.","geometry-solid-volume",A.d(["width",2,"height",2,"depth",2],p,o),q,"T\u1ea1o kh\u1ed1i h\u1ed9p c\xf3 th\u1ec3 t\xedch 12 \u0111\u01a1n v\u1ecb kh\u1ed1i v\xe0 di\u1ec7n t\xedch b\u1ec1 m\u1eb7t 32 \u0111\u01a1n v\u1ecb vu\xf4ng. Xoay kh\u1ed1i \u0111\u1ec3 quan s\xe1t c\xe1c m\u1eb7t.",B.b,s,"X\u01b0\u1edfng kh\u1ed1i kh\xf4ng gian",new A.dT())],n),"algebra",A.a([A.p(B.c,1,new A.dU(),"Cao = s\xe2u = 2 v\xe0 d\xe0i = 4: th\u1ec3 t\xedch l\xe0 4 \xd7 2 \xd7 2 = 16. M\xf4 h\xecnh ph\u1ea3i th\u1ecfa c\u1ea3 th\u1ec3 t\xedch l\u1eabn quan h\u1ec7 gi\u1eefa c\xe1c c\u1ea1nh.","Cho chi\u1ec1u cao v\xe0 chi\u1ec1u s\xe2u b\u1eb1ng nhau tr\u01b0\u1edbc. M\u1ed7i khi \u0111\u1ed5i chi\u1ec1u cao, chi\u1ec1u d\xe0i c\u1ea7n thay \u0111\u1ed5i th\u1ebf n\xe0o?","algebra-solid-relation",A.d(["width",2,"height",2,"depth",2],p,o),q,"D\u1ef1ng kh\u1ed1i h\u1ed9p c\xf3 th\u1ec3 t\xedch 16 \u0111\u01a1n v\u1ecb kh\u1ed1i. Chi\u1ec1u d\xe0i g\u1ea5p \u0111\xf4i chi\u1ec1u cao; chi\u1ec1u s\xe2u b\u1eb1ng chi\u1ec1u cao.",B.b,r,"M\u1ed9t kh\u1ed1i, ba quan h\u1ec7",new A.dV())],n)],p,u.X)})})();(function nativeSupport(){!function(){var t=function(a){var n={}
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
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.ax,SharedArrayBuffer:A.ax,ArrayBufferView:A.b3,DataView:A.bF,Float32Array:A.bG,Float64Array:A.bH,Int16Array:A.bI,Int32Array:A.bJ,Int8Array:A.bK,Uint16Array:A.bL,Uint32Array:A.bM,Uint8ClampedArray:A.b4,CanvasPixelArray:A.b4,Uint8Array:A.bN})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.ay.$nativeSuperclassTag="ArrayBufferView"
A.bf.$nativeSuperclassTag="ArrayBufferView"
A.bg.$nativeSuperclassTag="ArrayBufferView"
A.b1.$nativeSuperclassTag="ArrayBufferView"
A.bh.$nativeSuperclassTag="ArrayBufferView"
A.bi.$nativeSuperclassTag="ArrayBufferView"
A.b2.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
Function.prototype.$1$0=function(){return this()}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.iT
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()