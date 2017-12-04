haxe -D pak -D release --no-traces LD40.hxml
hl --standalone bin/LD40.exe LD40.hl
haxe -neko bin/pakker.n -lib stb_ogg_sound -lib heaps -main hxd.fmt.pak.Build
neko bin/pakker.n
MOVE res.pak bin/res.pak