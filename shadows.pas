(*
 *  Landscape with radial shadows.
 *)
program shadows;

const
  SEPARATION  = 100;
  BW          = 4;
  LIGHTHEIGHT = 64;
  BUFFER_EDGE = 128;
  BM          = BUFFER_EDGE * BUFFER_EDGE - 1;

var
  SinTab   : array [0..1023] of integer;
  Topo     : array [0..BM] of byte; {16k}
  Virt     : array [0..BM] of byte; {16k}
  LightMap : array [0..BM] of byte;  {16k}

procedure DrawLand(camX,camY:integer);
var
   d,x,y,c,lc  : integer;
   h,lh     : integer;
   i,j      : word;
   heights  : array [0..319] of integer;
   lheights : array [0..319] of integer;
   lcs      : array [0..319] of integer;
   tx,ty,
   txDelta,tyDelta : integer;
   angle    : integer;
   cval, cdelta : integer;
begin
  angle:=0;
  for x:=0 to 319 do begin
    heights[x]:=199; lheights[x]:=199;
  end;
  for d:=1 to 128 do begin
    tx:=camX+SinTab[(angle+SEPARATION+256) and 1023]*d;
    ty:=camY+SinTab[(angle+SEPARATION) and 1023]*d;
    txDelta:=(((SinTab[(angle-SEPARATION+256) and 1023]
               -SinTab[(angle+SEPARATION+256) and 1023]) div 2)*d) div 160;
    tyDelta:=(((SinTab[(angle-SEPARATION) and 1023]
               -SinTab[(angle+SEPARATION) and 1023]) div 2)*d) div 160;
    for x:=0 to 319 do begin
      i:=((tx shr 8)+((ty shr 8)*128)) and 16383;
      if (d<127) then begin
        h:=10+((63-Topo[i])*64 div d);
        h:=(h+lh) shr 1;
        h:=(h+lheights[x]) shr 1;
        lheights[x]:=h;
        lh:=h;
        c:=LightMap[i];
        c:=(c+lc) shr 1;
        c:=(c+lcs[x]) shr 1;
        lcs[x]:=c;
        lc:=c;
             end else begin
               h:=0; c:=0;
             end;
             if h<0 then h:=0;
             if h<heights[x] then begin
                j:=x+(h shl 8) + (h shl 6);
                for y:=h to heights[x] do begin
                    mem[$a000:j] := c shr 4 + 16;
                    inc(j,320);
                end;
               heights[x]:=h;
             end;

             inc(tx,txDelta);
             inc(ty,tyDelta);
         end;
     end;
end;

procedure MakeTopo;
var
   i,x,y,v :  integer;
begin
  i:=0;
  for y:=0 to 127 do begin
    for x:=0 to 127 do begin
      v:=63-(((x and 31)-15)*((x and 31)-15)+((y and 31)-15)*((y and 31)-15));
      if v < 0 then v :=0;
      topo[i] :=v;
      inc(i);
    end;
  end;
end;


(*
 *
 *
 *)
procedure RadialShadow(x,y:integer);
var
  r,a,h,hDelta,
  tx,ty,i,j,c,
  lx,ly         : integer;
begin
  for a:=0 to 255 do begin
    tx:=x; ty:=y;
    lx:=32*256; ly:=32*256;
    h:=LIGHTHEIGHT * 127; hDelta:=32767;
    for r:=0 to 63 do begin
      i:=((tx shr 8) and 127)+(((ty shr 8) and 127) shl 7);
      j:=((lx shr 8) and 63)+(((ly shr 8) and 63) shl 6);
      if Topo[i]>=(h shr 7) then begin
        h:=Topo[i];
        hDelta:=(LIGHTHEIGHT-h)*128 div (r+1);
        h:=h shl 7;
        c:=LightMap[i];
        inc(c,63 - r);
        if c>255 then c:=255;
        LightMap[i]:=c;
      end else begin
          LightMap[i]:=0;
      end;
      dec(h,hDelta);
      if h<0 then h:=0;
      inc(tx,SinTab[(a*4+256) and 1023]);
      inc(ty,SinTab[(a*4) and 1023]);
      inc(lx,SinTab[(a*4+256) and 1023]);
      inc(ly,SinTab[(a*4) and 1023]);
    end;
  end;
end;

procedure DrawLight(lx,ly,t : integer);
var
    i,x,y : integer;
begin

     for i:=0 to 16383 do LightMap[i]:=0;
      {
    asm
        mov di,offset LightMap
        xor ax,ax
        mov cx,8192
        rep stosw
    end;
       }
    RadialShadow(lx+SinTab[t*4 and 1023]*16+64*256,ly+SinTab[(t+256) and 1023]*16);



{    for y:=0 to 127 do begin
        for x:=0 to 127 do begin
            mem[$a000:x+y*320]:=LightMap[x+y*128] and $f0;
        end;
    end;}
end;

procedure MakeSinTab;
var
  i : integer;
begin
  for i:=0 to 1023 do begin
    SinTab[i]:=round(sin(i/512*pi)*256);
  end;
end;


procedure MainLoop;
var
   x,y,a    : integer;
begin
     randomize;
     repeat
           DrawLight(x,y,a);
           DrawLand(x,y);
           inc(a,1);
           inc(x,256);
     until port[$60]=1;
end;

begin
     randomize;
     MakeSinTab;
     asm
        mov ax, 13h
        int 10h
     end;
     MakeTopo;
     MainLoop;
     asm
        mov ax, 3h
        int 10h
     end;
end.
