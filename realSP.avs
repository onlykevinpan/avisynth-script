#MP_Pipeline("""
SetMemoryMax(3000)
LWLibavVideoSource("",threads=1)
nnedi3()
### prefetch: 26, 18
### export clip:
SetMemoryMax(1536)
LSFmod(defaults="fast", strength=40)
sharp=last
sharp_rm=sharp.removegrain(20)
sharp_mark(mode=2,sharp=sharp_rm)
src=last

### prefetch: 26, 18
### export clip: src,sharp_rm,sharp

### ###

### platform: win32
src
pre_o=HSQLUMA(LDN=sharp_rm)
pre=pre_o.Dither_Luma_Rebuild(S0=1,c=0.0625,lsb=true,uv=3)

### prefetch: 26, 18
### export clip: pre,pre_o
### pass clip:src,sharp

### ###


### platform: win32
SetmemoryMAX(3000)
super_search = MSuper(pre,pel=2,hpad=16,vpad=16,rfilter=4,sharp=2)
super_render = MSuper(pre_o,pel=2,hpad=16,vpad=16,levels=1,sharp=2)

search=5
blksize=16
blk2=blksize/2
overlap=blk2

thSAD=150
thSAD2=thSAD/2
thSADC=thSAD2

thSCD1       = 1600
thSCD2       = 130

limit        = 255
limitc       = limit

bv4  =  super_search.MAnalyse(isb = true, delta = 4,  overlap=    overlap,blksize=    blksize,   search=search,truemotion=true)
bv2  =  super_search.MAnalyse(isb = true, delta = 2,  overlap=    overlap,blksize=    blksize,   search=search,truemotion=true)

fv4  =  super_search.MAnalyse(isb = false, delta = 4, overlap=    overlap,blksize=    blksize,   search=search,truemotion=true)
fv2  =  super_search.MAnalyse(isb = false, delta = 2, overlap=    overlap,blksize=    blksize,   search=search,truemotion=true)

f1c     = sharp.MCompensate(super_render, fv2, thSAD=800, thSCD1=800, thSCD2=110)
b1c     = sharp.MCompensate(super_render, bv2, thSAD=800, thSCD1=800, thSCD2=110)

Tmax = sharp.mt_logic(f1c,"max",U=1,V=1).mt_logic(b1c,"max",U=1,V=1)
Tmin = sharp.mt_logic(f1c,"min",U=1,V=1).mt_logic(b1c,"min",U=1,V=1)
src=src.mt_clamp(Tmax, Tmin, 1, 1, U=1, V=1)

nr16=src.MDegrain2(super_render, bv2, fv2, bv4, fv4,thSAD=thSAD, thSADC=thSADC, thSCD1=thSCD1, thSCD2=thSCD2, limit=limit, limitc=limitc,lsb=true)

### prefetch: 16, 8
### export clip: nr16
### pass clip:src

### ###

### platform: win32
src16=src.U16
nred=nr16.dither_limit_dif16(src16,thr=1.0,elast=3.0)

### prefetch: 16, 8
### export clip:nred,src16
### pass clip:src,nr16

### ###

### platform: win32
smooth=NR16
unsmooth=nred.Dither_sub16(smooth, y=3, u=3, v=3, dif=True)
src162=nr16.Dither_add16(unsmooth, y=3, u=3, v=3, dif=True)

### prefetch: 16, 8
### export clip:src162
### pass clip:nred,src16,src

### ###

### platform: win32
PP=src162.Gradfun3(thr=0.35,lsb=true,lsb_in=true)
dbed=nred.f3kdb(15, 64, 64, 64, 0, 0, input_mode=1, output_mode=1).repair16(src16,24)

### prefetch: 16, 8
### export clip:PP,dbed
### pass clip:nred,src

### ###

### platform: win32
maskp=src.TEdgeMask( link=2, preblur=true, valon=-1 )
mask=maskp.mt_lut( "x 255 *" ).RemoveGrain(20)
PP3=Dither_merge16_8(dbed,pp,MASK, luma=FALSE)

### prefetch: 16, 8
### export clip:PP3
### pass clip:nred

### ###
PP3.Dither_bilateral16(nred,thr=2.5,2)
f3kdb(range=0, Y=0, Cb=0, Cr=0, grainY=0, grainC=0, dither_algo=2, dynamic_grain=true, keep_tv_range=false, input_mode=1, input_depth=16, output_mode=2, output_depth=16)
#""")