{ y0bi / wAMMA 2016-3-23 }
program bobsen;
var
   bobs        :  array [0..16383] of byte;
   t           : integer;
   sx, sy      : integer;
   curve       : array [0..255] of integer;
procedure DrawBob;
var
   x, y, a : integer;
begin
     for y:=-16 to 16 do begin
         for x:=-16 to 16 do begin
             a:=255 - x*x+y*y;
             if a<0 then a:=0;
             inc(bobs[((sx+x)+(sy+y)*128) and 16383], a div 32);
         end;
     end;
     sx:=sx+random(16)-8;
     sy:=sy+random(8)-4;
end;

procedure DrawScape;
var
   x, y, x2, y2, d, h, sy, c, ptr, dc, tempc : integer;
   heights                        : array [0..319] of integer;
   colors                         : array [0..319] of integer;
begin
     for x:=0 to 319 do begin
          heights[x]:=199;
          colors[x]:=0;
     end;
     for y:=100 downto 1 do begin
         d := 5000 div y;
         for x:=0 to 319 do begin
             x2:=(x-160) * d div 256;
             c:=(x2 xor (t+d)) and 255; {TODO bump this}
             ptr:=(x2+(t+d)*128) and 16383;
             h:=curve[bobs[ptr]];
             c:=128+bobs[(ptr-2) and 16383]-bobs[(ptr+2) and 16383]+
                    bobs[(ptr-256) and 16383]-bobs[(ptr+256) and 16383];
             c:=c-(d div 16);
             if c<0 then c:=0;
             if c>255 then c:=255;
             h:=100 + y - h*16 div d;
             if y=1 then h:=0;
             if heights[x]>h then begin

                dc:=((c-colors[x])*128) div (heights[x]-h);
                tempc:=c;
                c:=colors[x];
                colors[x]:=tempc;
                c:=c*128;
                for sy:=h to heights[x] do begin
                    mem[$a000:x + sy * 320]:=c div 128;
                    inc(c,dc);
                end;
                heights[x]:=h;
             end else colors[x]:=c;
         end;
     end;
end;

procedure Blur;
var
   i : integer;
begin
     for i:=0 to 16383 do begin
         bobs[i]:=(bobs[(i+1) and 16383]+bobs[(i-1) and 16383]+
         bobs[(i+128) and 16383]+bobs[(i-128) and 16383]) div 4;
     end;
end;



procedure MainLoop;
begin
     DrawBob;
     DrawScape;
     Blur;
     inc(t);
end;


procedure GrayPal;
var
   i : integer;
begin
     for i:=0 to 255 do begin
         port[$3c8]:=i;
         port[$3c9]:=i div 4;
         port[$3c9]:=i div 4;
         port[$3c9]:=63-(abs(127-i) div 2);
     end;
end;

procedure MakeCurve;
var
   i : integer;
begin
     for i:=0 to 255 do begin
         curve[i]:=round(sin(i*pi/128)*128)+128;
     end;
end;


begin
     asm
        mov ax,13h
        int 10h
     end;
     GrayPal;
     MakeCurve;
     repeat
           mainloop;
     until port[$60]=1;
     asm
        mov ax,3h
        int 10h
     end;
end.
