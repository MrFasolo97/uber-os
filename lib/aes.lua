--AES encryption. Found at http://www.computercraft.info/forums2/index.php?/topic/18930-aes-encryption/
bit={}
local function P9EyxJ2a(dl1ep7)if(dl1ep7-math.floor(dl1ep7)>0)then
error("trying to use bitwise operation on non-integer!")end end
local function A(hgD2)P9EyxJ2a(hgD2)if(hgD2 <0)then return
A(bit.bnot(math.abs(hgD2))+1)end;local AFz_n2c={}local h9IQpJMV=1;while(hgD2 >0)do local cpbB=
hgD2%2;if(cpbB==1)then AFz_n2c[h9IQpJMV]=1 else
AFz_n2c[h9IQpJMV]=0 end;hgD2=(hgD2-cpbB)/2
h9IQpJMV=h9IQpJMV+1 end
return AFz_n2c end
local function RKP2(ePyt0n)local XEEN4Er=table.getn(ePyt0n)local vsA=0;local _fxwQs=1;for i=1,XEEN4Er do
vsA=vsA+ePyt0n[i]*_fxwQs;_fxwQs=_fxwQs*2 end;return vsA end
local function k(K,hZMsaQl)local K27={}local Ln={}if
(table.getn(K)>table.getn(hZMsaQl))then K27=K;Ln=hZMsaQl else K27=hZMsaQl;Ln=K end;for i=
table.getn(Ln)+1,table.getn(K27)do Ln[i]=0 end end
function bit.bor(iF7eha,CZcYqRt)local JLUG=A(iF7eha)local jDCeX7NZ=A(CZcYqRt)k(JLUG,jDCeX7NZ)
local EzfgmC={}
local MgIU=math.max(table.getn(JLUG),table.getn(jDCeX7NZ))
for i=1,MgIU do if(JLUG[i]==0 and jDCeX7NZ[i]==0)then
EzfgmC[i]=0 else EzfgmC[i]=1 end end;return RKP2(EzfgmC)end
function bit.band(cN76A,GprT8aV)local o3tI=A(cN76A)local lUc=A(GprT8aV)k(o3tI,lUc)local u={}
local VHOmYg9=math.max(table.getn(o3tI),table.getn(lUc))for i=1,VHOmYg9 do
if(o3tI[i]==0 or lUc[i]==0)then u[i]=0 else u[i]=1 end end;return RKP2(u)end
function bit.bnot(IVmMiAf)local elhv7L=A(IVmMiAf)
local Oj5uwbn=math.max(table.getn(elhv7L),32)for i=1,Oj5uwbn do
if(elhv7L[i]==1)then elhv7L[i]=0 else elhv7L[i]=1 end end;return RKP2(elhv7L)end
function bit.bxor(x5yNWax,X9lu)local Jr87Wv=A(x5yNWax)local L9=A(X9lu)k(Jr87Wv,L9)local GrYJ={}
local SI=math.max(table.getn(Jr87Wv),table.getn(L9))for i=1,SI do
if(Jr87Wv[i]~=L9[i])then GrYJ[i]=1 else GrYJ[i]=0 end end;return RKP2(GrYJ)end
function bit.rshift(eWt,EWbh)P9EyxJ2a(eWt)local a=0;if(eWt<0)then
eWt=bit.bnot(math.abs(eWt))+1;a=2147483648 end;for i=1,EWbh do eWt=eWt/2
eWt=bit.bor(math.floor(eWt),a)end;return math.floor(eWt)end
function bit.blogic_rshift(Ab,Z1FO7lq)P9EyxJ2a(Ab)if(Ab<0)then
Ab=bit.bnot(math.abs(Ab))+1 end;for i=1,Z1FO7lq do Ab=Ab/2 end;return math.floor(Ab)end
function bit.lshift(Qanh,Q7wuDZwG)P9EyxJ2a(Qanh)if(Qanh<0)then
Qanh=bit.bnot(math.abs(Qanh))+1 end;for i=1,Q7wuDZwG do Qanh=Qanh*2 end;return
bit.band(Qanh,4294967295)end;buffer={}function buffer.new()return{}end
function buffer.addString(qj96AN6,LvtOaGRY)
table.insert(qj96AN6,LvtOaGRY)for i=#qj96AN6-1,1,-1 do
if#qj96AN6[i]>#qj96AN6[i+1]then break end
qj96AN6[i]=qj96AN6[i]..table.remove(qj96AN6)end end
function buffer.toString(DICkb)for i=#DICkb-1,1,-1 do
DICkb[i]=DICkb[i]..table.remove(DICkb)end;return DICkb[1]end;gf={}local Q__YLFQa=0x100;local Hipger=0xff;local NCOpGF_=0x11b;local MNCc_AE3={}local L={}function gf.add(DW2sMyQ,cOK)return
bit.bxor(DW2sMyQ,cOK)end;function gf.sub(WPQME,T)
return bit.bxor(WPQME,T)end
function gf.invert(j)if(j==1)then return 1 end
local IFaNq8v=Hipger-L[j]return MNCc_AE3[IFaNq8v]end
function gf.mul(K4EBI5Ls,w93P0qF)
if(K4EBI5Ls==0 or w93P0qF==0)then return 0 end;local BGOYJyRF=L[K4EBI5Ls]+L[w93P0qF]if(BGOYJyRF>=Hipger)then BGOYJyRF=
BGOYJyRF-Hipger end
return MNCc_AE3[BGOYJyRF]end
function gf.div(kg,m)if(kg==0)then return 0 end;local R=L[kg]-L[m]
if(R<0)then R=R+Hipger end;return MNCc_AE3[R]end;function gf.printLog()
for i=1,Q__YLFQa do print("log(",i-1,")=",L[i-1])end end;function gf.printExp()for i=1,Q__YLFQa do
print("exp(",i-1,")=",MNCc_AE3[i-1])end end
local function eCnd_yE()
local U=1
for i=0,Hipger-1 do MNCc_AE3[i]=U;L[U]=i
U=bit.bxor(bit.lshift(U,1),U)if U>Hipger then U=gf.sub(U,NCOpGF_)end end end;eCnd_yE()util={}
function util.byteParity(F9GW)
F9GW=bit.bxor(F9GW,bit.rshift(F9GW,4))F9GW=bit.bxor(F9GW,bit.rshift(F9GW,2))
F9GW=bit.bxor(F9GW,bit.rshift(F9GW,1))return bit.band(F9GW,1)end
function util.getByte(Y,KHcO0)if(KHcO0 ==0)then return bit.band(Y,0xff)else return
bit.band(bit.rshift(Y,KHcO0*8),0xff)end end;function util.putByte(xy7txhH,u0PM)
if(u0PM==0)then return bit.band(xy7txhH,0xff)else return bit.lshift(bit.band(xy7txhH,0xff),
u0PM*8)end end
function util.bytesToInts(gztv6c,IEGF5I,Q__YLFQa)
local WaHLYa={}
for i=0,Q__YLFQa-1 do
WaHLYa[i]=

util.putByte(gztv6c[IEGF5I+ (i*4)],3)+util.putByte(gztv6c[
IEGF5I+ (i*4)+1],2)+util.putByte(gztv6c[IEGF5I+ (i*4)+2],1)+util.putByte(gztv6c[IEGF5I+ (i*4)+3],0)end;return WaHLYa end
function util.intsToBytes(GrYkLyv,o0YjCejT,MN2PcKz,Q__YLFQa)Q__YLFQa=Q__YLFQa or#GrYkLyv
for i=0,Q__YLFQa do for j=0,3 do
o0YjCejT[MN2PcKz+i*4+ (3-j)]=util.getByte(GrYkLyv[i],j)end end;return o0YjCejT end
local function mA(rjy5A)local l=""for lnHM,PHBTYH in ipairs(rjy5A)do
l=l..string.format("%02x ",PHBTYH)end;return l end
function util.toHexString(Ivp)local Uvrs1I=type(Ivp)
if(Uvrs1I=="number")then return
string.format("%08x",Ivp)elseif(Uvrs1I=="table")then return mA(Ivp)elseif
(Uvrs1I=="string")then local YB={string.byte(Ivp,1,#Ivp)}return mA(YB)else return Ivp end end
function util.padByteString(W4JxbL)local Q2fBdLSP=#W4JxbL;local q=math.random(0,255)
local p=math.random(0,255)
local t1E=string.char(q,p,q,p,util.getByte(Q2fBdLSP,3),util.getByte(Q2fBdLSP,2),util.getByte(Q2fBdLSP,1),util.getByte(Q2fBdLSP,0))W4JxbL=t1E..W4JxbL
local XMF=math.ceil(#W4JxbL/16)*16-#W4JxbL;local XVsREP7=""for i=1,XMF do
XVsREP7=XVsREP7 ..string.char(math.random(0,255))end;return W4JxbL..XVsREP7 end
local function ik7m(LK7I)local X5c8rLoV={string.byte(LK7I,1,4)}if
(
X5c8rLoV[1]==X5c8rLoV[3]and X5c8rLoV[2]==X5c8rLoV[4])then return true end;return false end
function util.unpadByteString(EAbv)if(not ik7m(EAbv))then return nil end
local a3rNThT=


util.putByte(string.byte(EAbv,5),3)+util.putByte(string.byte(EAbv,6),2)+util.putByte(string.byte(EAbv,7),1)+util.putByte(string.byte(EAbv,8),0)return string.sub(EAbv,9,8+a3rNThT)end;function util.xorIV(qXgPGbNx,X)
for i=1,16 do qXgPGbNx[i]=bit.bxor(qXgPGbNx[i],X[i])end end;aes={}aes.ROUNDS="rounds"
aes.KEY_TYPE="type"aes.ENCRYPTION_KEY=1;aes.DECRYPTION_KEY=2;local Lptvv={}local QS5={}local z3U={}local oGl6hI={}
local _ZTDHg={}local J5x={}local d={}local sX2Lc={}local ahv8HA2i={}local w3dX={}
local l3H={0x01000000,0x02000000,0x04000000,0x08000000,0x10000000,0x20000000,0x40000000,0x80000000,0x1b000000,0x36000000,0x6c000000,0xd8000000,0xab000000,0x4d000000,0x9a000000,0x2f000000}
local function CiVE4(N6OhZ761)mask=0xf8;result=0
for i=1,8 do result=bit.lshift(result,1)
parity=util.byteParity(bit.band(N6OhZ761,mask))result=result+parity;lastbit=bit.band(mask,1)
mask=bit.band(bit.rshift(mask,1),0xff)if(lastbit~=0)then mask=bit.bor(mask,0x80)else
mask=bit.band(mask,0x7f)end end;return bit.bxor(result,0x63)end;local function _()
for i=0,255 do if(i~=0)then inverse=gf.invert(i)else inverse=i end
mapped=CiVE4(inverse)Lptvv[i]=mapped;QS5[mapped]=i end end
local function BLOXBLA()
for x=0,255 do
byte=Lptvv[x]
z3U[x]=
util.putByte(gf.mul(0x03,byte),0)+util.putByte(byte,1)+util.putByte(byte,2)+
util.putByte(gf.mul(0x02,byte),3)
oGl6hI[x]=util.putByte(byte,0)+util.putByte(byte,1)+
util.putByte(gf.mul(0x02,byte),2)+
util.putByte(gf.mul(0x03,byte),3)
_ZTDHg[x]=

util.putByte(byte,0)+util.putByte(gf.mul(0x02,byte),1)+util.putByte(gf.mul(0x03,byte),2)+util.putByte(byte,3)
J5x[x]=
util.putByte(gf.mul(0x02,byte),0)+
util.putByte(gf.mul(0x03,byte),1)+util.putByte(byte,2)+util.putByte(byte,3)end end
local function f()
for x=0,255 do byte=QS5[x]
d[x]=util.putByte(gf.mul(0x0b,byte),0)+
util.putByte(gf.mul(0x0d,byte),1)+
util.putByte(gf.mul(0x09,byte),2)+
util.putByte(gf.mul(0x0e,byte),3)
sX2Lc[x]=util.putByte(gf.mul(0x0d,byte),0)+
util.putByte(gf.mul(0x09,byte),1)+
util.putByte(gf.mul(0x0e,byte),2)+
util.putByte(gf.mul(0x0b,byte),3)
ahv8HA2i[x]=util.putByte(gf.mul(0x09,byte),0)+
util.putByte(gf.mul(0x0e,byte),1)+
util.putByte(gf.mul(0x0b,byte),2)+
util.putByte(gf.mul(0x0d,byte),3)
w3dX[x]=util.putByte(gf.mul(0x0e,byte),0)+
util.putByte(gf.mul(0x0b,byte),1)+
util.putByte(gf.mul(0x0d,byte),2)+
util.putByte(gf.mul(0x09,byte),3)end end
local function ZCmEBUb3(MJ3)local FIyF=bit.band(MJ3,0xff000000)return(bit.lshift(MJ3,8)+
bit.rshift(FIyF,24))end
local function W(z3yZq8wX)
return
util.putByte(Lptvv[util.getByte(z3yZq8wX,0)],0)+
util.putByte(Lptvv[util.getByte(z3yZq8wX,1)],1)+
util.putByte(Lptvv[util.getByte(z3yZq8wX,2)],2)+
util.putByte(Lptvv[util.getByte(z3yZq8wX,3)],3)end
function aes.expandEncryptionKey(J)local hZRYX45z={}local Fe=math.floor(#J/4)if(
(Fe~=4 and Fe~=6 and Fe~=8)or(Fe*4 ~=#J))then
print("Invalid key size: ",Fe)return nil end;hZRYX45z[aes.ROUNDS]=Fe+
6;hZRYX45z[aes.KEY_TYPE]=aes.ENCRYPTION_KEY;for i=0,Fe-1 do
hZRYX45z[i]=
util.putByte(J[
i*4+1],3)+util.putByte(J[i*4+2],2)+util.putByte(J[i*4+3],1)+util.putByte(J[
i*4+4],0)end
for i=Fe,(
hZRYX45z[aes.ROUNDS]+1)*4-1 do
local IkSswNv=hZRYX45z[i-1]
if(i%Fe==0)then IkSswNv=ZCmEBUb3(IkSswNv)IkSswNv=W(IkSswNv)
local UA3=math.floor(i/Fe)IkSswNv=bit.bxor(IkSswNv,l3H[UA3])elseif
(Fe>6 and i%Fe==4)then IkSswNv=W(IkSswNv)end
hZRYX45z[i]=bit.bxor(hZRYX45z[(i-Fe)],IkSswNv)end;return hZRYX45z end
local function qeg(M8)local tAD0h=util.getByte(M8,3)local c=util.getByte(M8,2)
local w=util.getByte(M8,1)local S5yDv8a=util.getByte(M8,0)
return



util.putByte(gf.add(gf.add(gf.add(gf.mul(0x0b,c),gf.mul(0x0d,w)),gf.mul(0x09,S5yDv8a)),gf.mul(0x0e,tAD0h)),3)+
util.putByte(gf.add(gf.add(gf.add(gf.mul(0x0b,w),gf.mul(0x0d,S5yDv8a)),gf.mul(0x09,tAD0h)),gf.mul(0x0e,c)),2)+
util.putByte(gf.add(gf.add(gf.add(gf.mul(0x0b,S5yDv8a),gf.mul(0x0d,tAD0h)),gf.mul(0x09,c)),gf.mul(0x0e,w)),1)+
util.putByte(gf.add(gf.add(gf.add(gf.mul(0x0b,tAD0h),gf.mul(0x0d,c)),gf.mul(0x09,w)),gf.mul(0x0e,S5yDv8a)),0)end
local function TzFt(NazGJ0)local b6rnw=util.getByte(NazGJ0,3)
local tBZNoRAm=util.getByte(NazGJ0,2)local FTAthr=util.getByte(NazGJ0,1)
local GyDAWeH1=util.getByte(NazGJ0,0)local GDRT8hzl=bit.bxor(GyDAWeH1,FTAthr)
local ioSnG4og=bit.bxor(tBZNoRAm,b6rnw)local q=bit.bxor(GDRT8hzl,ioSnG4og)
q=bit.bxor(q,gf.mul(0x08,q))
w=bit.bxor(q,gf.mul(0x04,bit.bxor(FTAthr,b6rnw)))
q=bit.bxor(q,gf.mul(0x04,bit.bxor(GyDAWeH1,tBZNoRAm)))
return



util.putByte(bit.bxor(bit.bxor(GyDAWeH1,q),gf.mul(0x02,bit.bxor(b6rnw,GyDAWeH1))),0)+
util.putByte(bit.bxor(bit.bxor(FTAthr,w),gf.mul(0x02,GDRT8hzl)),1)+
util.putByte(bit.bxor(bit.bxor(tBZNoRAm,q),gf.mul(0x02,bit.bxor(b6rnw,GyDAWeH1))),2)+
util.putByte(bit.bxor(bit.bxor(b6rnw,w),gf.mul(0x02,ioSnG4og)),3)end
function aes.expandDecryptionKey(o)local frK=aes.expandEncryptionKey(o)if(frK==nil)then
return nil end;frK[aes.KEY_TYPE]=aes.DECRYPTION_KEY
for i=4,(
frK[aes.ROUNDS]+1)*4-5 do frK[i]=qeg(frK[i])end;return frK end
local function nb1nLl(QkJpwIrI,iUcKTCk,z6UIKZ)for i=0,3 do
QkJpwIrI[i]=bit.bxor(QkJpwIrI[i],iUcKTCk[z6UIKZ*4+i])end end
local function CE(u7GD,S_)
S_[0]=bit.bxor(bit.bxor(bit.bxor(z3U[util.getByte(u7GD[0],3)],oGl6hI[util.getByte(u7GD[1],2)]),_ZTDHg[util.getByte(u7GD[2],1)]),J5x[util.getByte(u7GD[3],0)])
S_[1]=bit.bxor(bit.bxor(bit.bxor(z3U[util.getByte(u7GD[1],3)],oGl6hI[util.getByte(u7GD[2],2)]),_ZTDHg[util.getByte(u7GD[3],1)]),J5x[util.getByte(u7GD[0],0)])
S_[2]=bit.bxor(bit.bxor(bit.bxor(z3U[util.getByte(u7GD[2],3)],oGl6hI[util.getByte(u7GD[3],2)]),_ZTDHg[util.getByte(u7GD[0],1)]),J5x[util.getByte(u7GD[1],0)])
S_[3]=bit.bxor(bit.bxor(bit.bxor(z3U[util.getByte(u7GD[3],3)],oGl6hI[util.getByte(u7GD[0],2)]),_ZTDHg[util.getByte(u7GD[1],1)]),J5x[util.getByte(u7GD[2],0)])end
local function yol00(y8fOZTt,VslEw4)
VslEw4[0]=

util.putByte(Lptvv[util.getByte(y8fOZTt[0],3)],3)+
util.putByte(Lptvv[util.getByte(y8fOZTt[1],2)],2)+
util.putByte(Lptvv[util.getByte(y8fOZTt[2],1)],1)+
util.putByte(Lptvv[util.getByte(y8fOZTt[3],0)],0)
VslEw4[1]=

util.putByte(Lptvv[util.getByte(y8fOZTt[1],3)],3)+
util.putByte(Lptvv[util.getByte(y8fOZTt[2],2)],2)+
util.putByte(Lptvv[util.getByte(y8fOZTt[3],1)],1)+
util.putByte(Lptvv[util.getByte(y8fOZTt[0],0)],0)
VslEw4[2]=

util.putByte(Lptvv[util.getByte(y8fOZTt[2],3)],3)+
util.putByte(Lptvv[util.getByte(y8fOZTt[3],2)],2)+
util.putByte(Lptvv[util.getByte(y8fOZTt[0],1)],1)+
util.putByte(Lptvv[util.getByte(y8fOZTt[1],0)],0)
VslEw4[3]=

util.putByte(Lptvv[util.getByte(y8fOZTt[3],3)],3)+
util.putByte(Lptvv[util.getByte(y8fOZTt[0],2)],2)+
util.putByte(Lptvv[util.getByte(y8fOZTt[1],1)],1)+
util.putByte(Lptvv[util.getByte(y8fOZTt[2],0)],0)end
local function ciAHJ(SZr5fiS4,lfS)
lfS[0]=bit.bxor(bit.bxor(bit.bxor(d[util.getByte(SZr5fiS4[0],3)],sX2Lc[util.getByte(SZr5fiS4[3],2)]),ahv8HA2i[util.getByte(SZr5fiS4[2],1)]),w3dX[util.getByte(SZr5fiS4[1],0)])
lfS[1]=bit.bxor(bit.bxor(bit.bxor(d[util.getByte(SZr5fiS4[1],3)],sX2Lc[util.getByte(SZr5fiS4[0],2)]),ahv8HA2i[util.getByte(SZr5fiS4[3],1)]),w3dX[util.getByte(SZr5fiS4[2],0)])
lfS[2]=bit.bxor(bit.bxor(bit.bxor(d[util.getByte(SZr5fiS4[2],3)],sX2Lc[util.getByte(SZr5fiS4[1],2)]),ahv8HA2i[util.getByte(SZr5fiS4[0],1)]),w3dX[util.getByte(SZr5fiS4[3],0)])
lfS[3]=bit.bxor(bit.bxor(bit.bxor(d[util.getByte(SZr5fiS4[3],3)],sX2Lc[util.getByte(SZr5fiS4[2],2)]),ahv8HA2i[util.getByte(SZr5fiS4[1],1)]),w3dX[util.getByte(SZr5fiS4[0],0)])end
local function QR7o_yG5(MJ4yEu8X,VK)
VK[0]=
util.putByte(QS5[util.getByte(MJ4yEu8X[0],3)],3)+
util.putByte(QS5[util.getByte(MJ4yEu8X[3],2)],2)+
util.putByte(QS5[util.getByte(MJ4yEu8X[2],1)],1)+
util.putByte(QS5[util.getByte(MJ4yEu8X[1],0)],0)
VK[1]=
util.putByte(QS5[util.getByte(MJ4yEu8X[1],3)],3)+
util.putByte(QS5[util.getByte(MJ4yEu8X[0],2)],2)+
util.putByte(QS5[util.getByte(MJ4yEu8X[3],1)],1)+
util.putByte(QS5[util.getByte(MJ4yEu8X[2],0)],0)
VK[2]=
util.putByte(QS5[util.getByte(MJ4yEu8X[2],3)],3)+
util.putByte(QS5[util.getByte(MJ4yEu8X[1],2)],2)+
util.putByte(QS5[util.getByte(MJ4yEu8X[0],1)],1)+
util.putByte(QS5[util.getByte(MJ4yEu8X[3],0)],0)
VK[3]=
util.putByte(QS5[util.getByte(MJ4yEu8X[3],3)],3)+
util.putByte(QS5[util.getByte(MJ4yEu8X[2],2)],2)+
util.putByte(QS5[util.getByte(MJ4yEu8X[1],1)],1)+
util.putByte(QS5[util.getByte(MJ4yEu8X[0],0)],0)end
function aes.encrypt(fy,XsKS,ML4cGA,RT91f,cienY066)ML4cGA=ML4cGA or 1;RT91f=RT91f or{}cienY066=cienY066 or 1
local cYDOw={}local Er0Qrsv={}if(fy[aes.KEY_TYPE]~=aes.ENCRYPTION_KEY)then
print("No encryption key: ",fy[aes.KEY_TYPE])return end
cYDOw=util.bytesToInts(XsKS,ML4cGA,4)nb1nLl(cYDOw,fy,0)local uPK=1
while
(uPK<fy[aes.ROUNDS]-1)do CE(cYDOw,Er0Qrsv)nb1nLl(Er0Qrsv,fy,uPK)uPK=uPK+1
CE(Er0Qrsv,cYDOw)nb1nLl(cYDOw,fy,uPK)uPK=uPK+1 end;CE(cYDOw,Er0Qrsv)nb1nLl(Er0Qrsv,fy,uPK)uPK=uPK+1
yol00(Er0Qrsv,cYDOw)nb1nLl(cYDOw,fy,uPK)
return util.intsToBytes(cYDOw,RT91f,cienY066)end
function aes.decrypt(zCHw,Z4G86,uKHo_,goYxWnk,_SDG6Yf)uKHo_=uKHo_ or 1;goYxWnk=goYxWnk or{}_SDG6Yf=_SDG6Yf or 1
local sr={}local yYalGD={}if
(zCHw[aes.KEY_TYPE]~=aes.DECRYPTION_KEY)then
print("No decryption key: ",zCHw[aes.KEY_TYPE])return end
sr=util.bytesToInts(Z4G86,uKHo_,4)nb1nLl(sr,zCHw,zCHw[aes.ROUNDS])
local T2NxGO6=zCHw[aes.ROUNDS]-1
while(T2NxGO6 >2)do ciAHJ(sr,yYalGD)
nb1nLl(yYalGD,zCHw,T2NxGO6)T2NxGO6=T2NxGO6-1;ciAHJ(yYalGD,sr)
nb1nLl(sr,zCHw,T2NxGO6)T2NxGO6=T2NxGO6-1 end;ciAHJ(sr,yYalGD)nb1nLl(yYalGD,zCHw,T2NxGO6)
T2NxGO6=T2NxGO6-1;QR7o_yG5(yYalGD,sr)nb1nLl(sr,zCHw,T2NxGO6)return
util.intsToBytes(sr,goYxWnk,_SDG6Yf)end;_()BLOXBLA()f()ciphermode={}
function ciphermode.encryptString(akSIw,eeowa0,W8bPb9S)
local p=iv or{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}local mo76xjY=aes.expandEncryptionKey(akSIw)
local n=buffer.new()for i=1,#eeowa0/16 do local H=(i-1)*16+1
local w={string.byte(eeowa0,H,H+15)}W8bPb9S(mo76xjY,w,p)
buffer.addString(n,string.char(unpack(w)))end;return
buffer.toString(n)end
function ciphermode.encryptECB(i,W_APiDR,QklwAcAr)aes.encrypt(i,W_APiDR,1,W_APiDR,1)end
function ciphermode.encryptCBC(uly,u_ergs7X,cP)util.xorIV(u_ergs7X,cP)
aes.encrypt(uly,u_ergs7X,1,u_ergs7X,1)for j=1,16 do cP[j]=u_ergs7X[j]end end;function ciphermode.encryptOFB(gSE6_XC3,vWuu3o6,ELqi)aes.encrypt(gSE6_XC3,ELqi,1,ELqi,1)
util.xorIV(vWuu3o6,ELqi)end;function ciphermode.encryptCFB(V,dd4yIs,QwsH)
aes.encrypt(V,QwsH,1,QwsH,1)util.xorIV(dd4yIs,QwsH)
for j=1,16 do QwsH[j]=dd4yIs[j]end end
function ciphermode.decryptString(ri,fDsTm7,nPQKe2z)local SUGF=
iv or{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}local O_vG;if
(
nPQKe2z==ciphermode.decryptOFB or nPQKe2z==ciphermode.decryptCFB)then O_vG=aes.expandEncryptionKey(ri)else
O_vG=aes.expandDecryptionKey(ri)end
local aT_g0=buffer.new()
for i=1,#fDsTm7/16 do local dfKS5=(i-1)*16+1
local h={string.byte(fDsTm7,dfKS5,dfKS5+15)}SUGF=nPQKe2z(O_vG,h,SUGF)
buffer.addString(aT_g0,string.char(unpack(h)))end;return buffer.toString(aT_g0)end;function ciphermode.decryptECB(_zOVUMp,tece4X,iM_rG)aes.decrypt(_zOVUMp,tece4X,1,tece4X,1)
return iM_rG end
function ciphermode.decryptCBC(DUUAFvb,tZcUH,NLtd)
local sQB={}for j=1,16 do sQB[j]=tZcUH[j]end
aes.decrypt(DUUAFvb,tZcUH,1,tZcUH,1)util.xorIV(tZcUH,NLtd)return sQB end
function ciphermode.decryptOFB(Xi4DWabT,Gc4hWD3,i0AP0Vf)
aes.encrypt(Xi4DWabT,i0AP0Vf,1,i0AP0Vf,1)util.xorIV(Gc4hWD3,i0AP0Vf)return i0AP0Vf end
function ciphermode.decryptCFB(zL,bg,ny)local jh={}for j=1,16 do jh[j]=bg[j]end
aes.encrypt(zL,ny,1,ny,1)util.xorIV(bg,ny)return jh end;AES128=16;AES192=24;AES256=32;ECBMODE=1;CBCMODE=2;OFBMODE=3;CFBMODE=4
local function tLAgUyWx(Jv3cG,Mtp)local dKb=Mtp;if
(Mtp==AES192)then dKb=32 end;if(dKb>#Jv3cG)then local PC=""for i=1,dKb-#Jv3cG do PC=PC..
string.char(0)end;Jv3cG=Jv3cG..PC else
Jv3cG=string.sub(Jv3cG,1,dKb)end;local PWDG5={string.byte(Jv3cG,1,
#Jv3cG)}
Jv3cG=ciphermode.encryptString(PWDG5,Jv3cG,ciphermode.encryptCBC)Jv3cG=string.sub(Jv3cG,1,Mtp)return
{string.byte(Jv3cG,1,#Jv3cG)}end
function AESencrypt(d15g,sN4mp,t,_CuESLMQg)assert(d15g~=nil,"Empty password.")
assert(d15g~=nil,"Empty data.")local _CuESLMQg=_CuESLMQg or CBCMODE;local t=t or AES128
local XeDL=tLAgUyWx(d15g,t)local qeY=util.padByteString(sN4mp)
if(_CuESLMQg==ECBMODE)then return
ciphermode.encryptString(XeDL,qeY,ciphermode.encryptECB)elseif(_CuESLMQg==CBCMODE)then return
ciphermode.encryptString(XeDL,qeY,ciphermode.encryptCBC)elseif(_CuESLMQg==OFBMODE)then return
ciphermode.encryptString(XeDL,qeY,ciphermode.encryptOFB)elseif(_CuESLMQg==CFBMODE)then return
ciphermode.encryptString(XeDL,qeY,ciphermode.encryptCFB)else return nil end end
function AESdecrypt(Dr5X_y7S,vzFU,wnXNOREN,Ci)local Ci=Ci or CBCMODE;local wnXNOREN=wnXNOREN or AES128
local PVY=tLAgUyWx(Dr5X_y7S,wnXNOREN)local CUy_Q
if(Ci==ECBMODE)then
CUy_Q=ciphermode.decryptString(PVY,vzFU,ciphermode.decryptECB)elseif(Ci==CBCMODE)then
CUy_Q=ciphermode.decryptString(PVY,vzFU,ciphermode.decryptCBC)elseif(Ci==OFBMODE)then
CUy_Q=ciphermode.decryptString(PVY,vzFU,ciphermode.decryptOFB)elseif(Ci==CFBMODE)then
CUy_Q=ciphermode.decryptString(PVY,vzFU,ciphermode.decryptCFB)end;result=util.unpadByteString(CUy_Q)
if(result==nil)then return nil end;return result end
